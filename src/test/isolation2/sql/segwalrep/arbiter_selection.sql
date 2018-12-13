-- Tests arbiter selection
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

SELECT role, content, mode, status, master_prober FROM gp_segment_configuration;
-- stop master prober in order to trigger a mirror promotion and arbiter selection
select pg_ctl((select datadir from gp_segment_configuration c
    where c.master_prober = true), 'stop');

-- trigger failover
select gp_request_fts_probe_scan();

-- expect: to see the content 0, preferred primary is mirror and it's down
-- the preferred mirror is primary and it's up and not-in-sync
-- arbiter has changed
select content, preferred_role, role, status, mode, master_prober
    from gp_segment_configuration;

-- fully recover the failed primary as new mirror
!\retcode gprecoverseg -aF;

-- trigger failover
select gp_request_fts_probe_scan();

-- expect: to see roles flipped and in sync
select content, preferred_role, role, status, mode
from gp_segment_configuration
where content = 0;

