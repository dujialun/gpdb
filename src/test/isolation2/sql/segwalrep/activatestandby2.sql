--------------------------------------------------------------------------------
-- Master down, standby not promoted, activate standby, master prober probe scan
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Master down, standby not promoted, activate standby, master prober probe scan
--------------------------------------------------------------------------------

-- cache session on seg0 where master prober on it
0U: select 1;
-- skip master prober always
1: select gp_inject_fault('fts_probe', 'reset', dbid)
    from gp_segment_configuration
    where master_prober = true;
1: select gp_inject_fault_infinite('fts_probe', 'skip', dbid)
    from gp_segment_configuration
    where master_prober = true;
-- force scan to trigger the fault
0U: select gp_request_fts_probe_scan();
-- verify the failure should be triggered once
1: select gp_wait_until_triggered_fault('fts_probe', 1, dbid)
    from gp_segment_configuration
    where master_prober = true;

-- stop master
1: select pg_ctl((select datadir from gp_segment_configuration c
    where c.role='p' and c.content=-1), 'stop');
1q:

-- activate standby
-- start_ignore
0U: select activate_standby(datadir, port) from tmp_standby_promotion where preferred_role = 'm';
-- end_ignore

-- resume master prober
2: \c 16432;
2: select gp_inject_fault('fts_probe', 'reset', dbid)
    from gp_segment_configuration
    where master_prober = true;

-- force scan to trigger the fault
0U: select gp_request_fts_probe_scan();
0U: select * from gp_segment_configuration;

---------------------------------------------------------------------------------------------------
-- recover to old cluster
---------------------------------------------------------------------------------------------------

-- init a new standby using original master data directory
-- start_ignore
2: select init_standby(datadir, hostname, port, 16432) from tmp_standby_promotion where preferred_role = 'p';
-- end_ignore

-- stop current master
2: select pg_ctl((select datadir from gp_segment_configuration c
    where c.role='p' and c.content=-1), 'stop');
2q:

-- trigger failover
0U: select gp_request_fts_probe_scan();
0U: select pg_sleep(1);

-- init a new standby using original standby data directory
-- start_ignore
1: select init_standby(datadir, hostname, port, 15432) from tmp_standby_promotion where preferred_role = 'm';
-- end_ignore
1: DROP TABLE tmp_standby_promotion;
0Uq:
1q:
