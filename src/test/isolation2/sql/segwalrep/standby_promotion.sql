-- Tests standby promotion triggered by FTS in 2 different scenarios.
--
-- 1st: Shut-down of master and hence unavailability of master
-- leading to standby promotion. In this case the connection between
-- master and standby is disconnected prior to promotion and
-- walreceiver doesn't exist.
--
-- 2nd: Master is alive but using fault injector simulated to not
-- respond to fts. This helps to validate fts time-out logic for
-- probes. Plus also standby promotion triggered while connection
-- between master and standby is still alive and hence walreceiver
-- also exist during promotion.

-- start_ignore
create language plpythonu;
-- end_ignore

create extension if not exists gp_inject_fault;
create or replace function pg_ctl(datadir text, command text)
returns text as $$
    import subprocess

    cmd = 'pg_ctl -D %s ' % datadir
    if command in ('stop'):
        cmd = cmd + '-w -m immediate %s' % command
    else:
        return 'Invalid command input'

    return subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True).replace('.', '')
$$ language plpythonu;

create or replace function init_standby(datadir text, hostname text, port int, envport int)
returns text as $$
    import subprocess

    cmd = 'rm -rf %s ' % datadir
    subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True).replace('.', '')

    cmd = 'PGPORT=%d; gpinitstandby -a -s %s -P %d -F %s' % (envport, hostname, port, datadir)
    return subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True).replace('.', '')
$$ language plpythonu;

-- set GUCs to speed-up the test
!\retcode gpconfig -c gp_fts_probe_retries -v 2;
!\retcode gpconfig -c gp_fts_probe_timeout -v 5;
!\retcode gpstop -u;

CREATE TABLE tmp_standby_promotion (datadir text, hostname text, port int, preferred_role char);
INSERT INTO tmp_standby_promotion
    SELECT datadir, hostname, port, preferred_role from gp_segment_configuration
    WHERE content = -1;

-- cache session on seg0 where master prober on it
0U: select 1;

SELECT role, preferred_role, content, mode, status FROM gp_segment_configuration;

-- stop master in order to trigger standby promotion
select pg_ctl((select datadir from gp_segment_configuration c
where c.role='p' and c.content=-1), 'stop');

-- trigger failover
0U: select gp_request_fts_probe_scan();

-- As master is down, standby has been promoted, so connect to old standby
-- port as new master
1: \c 16432;
1: select content, preferred_role, role, status, mode
from gp_segment_configuration
where content = -1;

-- init a new standby using original master data directory
-- start_ignore
1: select init_standby(
    (select datadir from tmp_standby_promotion where preferred_role = 'p'),
    (select hostname from tmp_standby_promotion where preferred_role = 'p'),
    (select port from tmp_standby_promotion where preferred_role = 'p'),
    (select port from tmp_standby_promotion where preferred_role = 'm'));
-- end_ignore
1: select content, preferred_role, role, status, mode
from gp_segment_configuration
where content = -1;

-- inject fts handler to simulate fts probe timeout
1: select gp_inject_fault_infinite('fts_handle_message', 'infinite_loop', dbid)
from gp_segment_configuration
where content = -1 and role = 'p';
1q:

-- trigger failover
0U: show gp_fts_probe_retries;
0U: show gp_fts_probe_timeout;
0U: select gp_request_fts_probe_scan();

-- trigger one more probe right away which mostly results in sending
-- promotion request again to standby, while its going through
-- promotion, which is nice condition to test as well.
0U: select gp_request_fts_probe_scan();

-- expect old master restored back to its preferred role, but standby is down
1: \c 15432;
1: select content, preferred_role, role, status, mode
from gp_segment_configuration
where content = -1;

-- set GUCs to speed-up the test
!\retcode gpconfig -r gp_fts_probe_retries;
!\retcode gpconfig -r gp_fts_probe_timeout;
!\retcode gpstop -u;

-- restore original standby
1: select pg_ctl((select datadir from tmp_standby_promotion where preferred_role = 'm'), 'stop');
-- start_ignore
1: select init_standby(
    (select datadir from tmp_standby_promotion where preferred_role = 'm'),
    (select hostname from tmp_standby_promotion where preferred_role = 'm'),
    (select port from tmp_standby_promotion where preferred_role = 'm'),
    (select port from tmp_standby_promotion where preferred_role = 'p'));
-- end_ignore

1: select content, preferred_role, role, status, mode
from gp_segment_configuration
where content = -1;

1: DROP TABLE tmp_standby_promotion;
1q:
