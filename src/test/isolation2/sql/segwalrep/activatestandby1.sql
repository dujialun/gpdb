--
--
--

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

    cmd = 'env PGPORT=%d gpinitstandby -a -s %s -P %d -F %s' % (envport, hostname, port, datadir)
    return subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True).replace('.', '')
$$ language plpythonu;

create or replace function activate_standby(datadir text, port int)
returns text as $$
    import subprocess

    cmd = 'env PGPORT=%d gpactivatestandby -a -d %s' % (port, datadir)
    return subprocess.check_output(cmd, stderr=subprocess.STDOUT, shell=True).replace('.', '')
$$ language plpythonu;

-- save the master information into a table
CREATE TABLE tmp_standby_promotion AS SELECT datadir, hostname, port, preferred_role
FROM gp_segment_configuration WHERE content = -1 distributed replicated;

--------------------------------------------------
-- Master down, standby promoted, activate standby
--------------------------------------------------

-- cache session on seg0 where master prober on it
0U: select 1;

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

0U: select * from gp_segment_configuration;

-- activate a promoted standby will fail for the critical required file recovery.conf is not present
-- start_ignore
1: select activate_standby(datadir, port) from tmp_standby_promotion where preferred_role = 'm';
-- end_ignore

---------------------------------------------------------------------------------------------------
-- recover to old cluster
---------------------------------------------------------------------------------------------------

-- init a new standby using original master data directory
-- start_ignore
1: select init_standby(datadir, hostname, port, 16432) from tmp_standby_promotion where preferred_role = 'p';
-- end_ignore

-- stop current master
1: select pg_ctl((select datadir from gp_segment_configuration c
    where c.role='p' and c.content=-1), 'stop');
1q:

-- trigger failover
0U: select gp_request_fts_probe_scan();
0U: select pg_sleep(1);

-- init a new standby using original standby data directory
-- start_ignore
2: select init_standby(datadir, hostname, port, 15432) from tmp_standby_promotion where preferred_role = 'm';
-- end_ignore
2: DROP TABLE tmp_standby_promotion;
0Uq:
2q:
