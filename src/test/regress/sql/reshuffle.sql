\set options ''

drop schema if exists test_reshuffle;
create schema test_reshuffle;
set search_path='test_reshuffle';

set gp_create_table_default_numsegments to 'any';

-- Hash distributed tables
set gp_create_table_any_numsegments to 2;
Create table t1(a int, b int, c int) :options;
insert into t1 select i,i,0 from generate_series(1,100) I;
Update t1 set c = gp_segment_id;
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
Alter table t1 set with (reshuffle);
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
select numsegments from gp_distribution_policy where localoid='t1'::regclass;
drop table t1;

set gp_create_table_any_numsegments to 1;
Create table t1(a int, b int, c int) :options;
insert into t1 select i,i,0 from generate_series(1,100) I;
Update t1 set c = gp_segment_id;
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
Alter table t1 set with (reshuffle);
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
select numsegments from gp_distribution_policy where localoid='t1'::regclass;
drop table t1;

set gp_create_table_any_numsegments to 2;
Create table t1(a int, b int, c int) :options distributed by (a,b);
insert into t1 select i,i,0 from generate_series(1,100) I;
Update t1 set c = gp_segment_id;
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
Alter table t1 set with (reshuffle);
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
select numsegments from gp_distribution_policy where localoid='t1'::regclass;
drop table t1;

set gp_create_table_any_numsegments to 1;
Create table t1(a int, b int, c int) :options distributed by (a,b);
insert into t1 select i,i,0 from generate_series(1,100) I;
Update t1 set c = gp_segment_id;
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
Alter table t1 set with (reshuffle);
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
select numsegments from gp_distribution_policy where localoid='t1'::regclass;
drop table t1;

set gp_create_table_any_numsegments to 1;
Create table t1(a int, b int, c int) with OIDS distributed by (a,b);
insert into t1 select i,i,0 from generate_series(1,100) I;
Update t1 set c = gp_segment_id;
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
Alter table t1 set with (reshuffle);
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
select numsegments from gp_distribution_policy where localoid='t1'::regclass;
drop table t1;


-- Test NULLs.
set gp_create_table_any_numsegments to 2;
Create table t1(a int, b int, c int) :options distributed by (a,b,c);
insert into t1 values
  (1,    1,    1   ),
  (null, 2,    2   ),
  (3,    null, 3   ),
  (4,    4,    null),
  (null, null, 5   ),
  (null, 6,    null),
  (7,    null, null),
  (null, null, null);
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
Alter table t1 set with (reshuffle);
Select count(*) from t1 where gp_segment_id=0;
Select count(*) from t1 where gp_segment_id=1;
Select count(*) from t1 where gp_segment_id=2;
select numsegments from gp_distribution_policy where localoid='t1'::regclass;
drop table t1;

set gp_create_table_any_numsegments to 1;
Create table t1(a int, b int, c int) :options distributed by (a) partition by list(b) (partition t1_1 values(1), partition t1_2 values(2), default partition other);
insert into t1 select i,i,0 from generate_series(1,100) I;
Alter table t1 set with (reshuffle);
Select count(*) from t1;
Select count(*) > 0 from t1 where gp_segment_id=1;
Select count(*) > 0 from t1 where gp_segment_id=2;
drop table t1;

set gp_create_table_any_numsegments to 2;
Create table t1(a int, b int, c int) :options distributed by (a) partition by list(b) (partition t1_1 values(1), partition t1_2 values(2), default partition other);
insert into t1 select i,i,0 from generate_series(1,100) I;
Alter table t1 set with (reshuffle);
Select count(*) from t1;
Select count(*) > 0 from t1 where gp_segment_id=2;
drop table t1;

set gp_create_table_any_numsegments to 1;
Create table t1(a int, b int, c int) :options distributed by (a,b) partition by list(b) (partition t1_1 values(1), partition t1_2 values(2), default partition other);
insert into t1 select i,i,0 from generate_series(1,100) I;
Alter table t1 set with (reshuffle);
Select count(*) from t1;
Select count(*) > 0 from t1 where gp_segment_id=1;
Select count(*) > 0 from t1 where gp_segment_id=2;
drop table t1;

set gp_create_table_any_numsegments to 2;
Create table t1(a int, b int, c int) :options distributed by (a,b) partition by list(b) (partition t1_1 values(1), partition t1_2 values(2), default partition other);
insert into t1 select i,i,0 from generate_series(1,100) I;
Alter table t1 set with (reshuffle);
Select count(*) from t1;
Select count(*) > 0 from t1 where gp_segment_id=2;
drop table t1;

-- Random distributed tables
set gp_create_table_any_numsegments to 1;
Create table r1(a int, b int, c int) :options distributed randomly;
insert into r1 select i,i,0 from generate_series(1,100) I;
Update r1 set c = gp_segment_id;
Select count(*) from r1;
Alter table r1 set with (reshuffle);
Select count(*) from r1;
Select count(*) > 0 from r1 where gp_segment_id=2;
drop table r1;

set gp_create_table_any_numsegments to 1;
Create table r1(a int, b int, c int) with OIDS distributed randomly;
insert into r1 select i,i,0 from generate_series(1,100) I;
Update r1 set c = gp_segment_id;
Select count(*) from r1;
Alter table r1 set with (reshuffle);
Select count(*) from r1;
Select count(*) > 0 from r1 where gp_segment_id=2;
drop table r1;

set gp_create_table_any_numsegments to 2;
Create table r1(a int, b int, c int) :options distributed randomly;
insert into r1 select i,i,0 from generate_series(1,100) I;
Update r1 set c = gp_segment_id;
Select count(*) from r1;
Alter table r1 set with (reshuffle);
Select count(*) from r1;
Select count(*) > 0 from r1 where gp_segment_id=2;
drop table r1;

set gp_create_table_any_numsegments to 1;
Create table r1(a int, b int, c int) :options distributed randomly partition by list(b) (partition r1_1 values(1), partition r1_2 values(2), default partition other);
insert into r1 select i,i,0 from generate_series(1,100) I;
Alter table r1 set with (reshuffle);
Select count(*) from r1;
Select count(*) > 0 from r1 where gp_segment_id=1;
Select count(*) > 0 from r1 where gp_segment_id=2;
drop table r1;

set gp_create_table_any_numsegments to 2;
Create table r1(a int, b int, c int) :options distributed randomly partition by list(b) (partition r1_1 values(1), partition r1_2 values(2), default partition other);
insert into r1 select i,i,0 from generate_series(1,100) I;
Alter table r1 set with (reshuffle);
Select count(*) from r1;
Select count(*) > 0 from r1 where gp_segment_id=1;
Select count(*) > 0 from r1 where gp_segment_id=2;
drop table r1;

-- Replicated tables
-- We have to make sure replicated table successfully reshuffled.
-- Currently we could only connect to the specific segments in utility mode
-- to see if the data is consistent there. We create some python function here.
-- The case can only work under the assumption: it's running on 3-segment cluster
-- in a single machine.
-- start_ignore
drop language plpythonu;
-- end_ignore
create language plpythonu;

create function select_on_segment(sql text, segid int) returns int as
$$
import pygresql.pg as pg
conn = pg.connect(dbname='regression')
port = conn.query("select port from gp_segment_configuration where content = %d and role = 'p'" % segid).getresult()[0][0]
conn.close()

conn = pg.connect(dbname='regression', opt='-c gp_session_role=utility', port=port)
conn.query("set search_path = 'test_reshuffle'")
r = conn.query(sql).getresult()
conn.close()

return r[0][0]
$$
LANGUAGE plpythonu;

set gp_create_table_any_numsegments to 1;
Create table r1(a int, b int, c int) :options distributed replicated;
insert into r1 select i,i,0 from generate_series(1,100) I;
Select count(*) from r1;
Select select_on_segment('Select count(*) from r1;', 1);
Select select_on_segment('Select count(*) from r1;', 2);
Alter table r1 set with (reshuffle);
Select select_on_segment('Select count(*) from r1;', 1);
Select select_on_segment('Select count(*) from r1;', 2);
drop table r1;

set gp_create_table_any_numsegments to 2;
Create table r1(a int, b int, c int) :options distributed replicated;
insert into r1 select i,i,0 from generate_series(1,100) I;
Select count(*) from r1;
Select select_on_segment('Select count(*) from r1;', 2);
Alter table r1 set with (reshuffle);
Select count(*) from r1;
Select select_on_segment('Select count(*) from r1;', 2);
drop table r1;

set gp_create_table_any_numsegments to 2;
Create table r1(a int, b int, c int) with OIDS distributed replicated;
insert into r1 select i,i,0 from generate_series(1,100) I;
Select count(*) from r1;
Select select_on_segment('Select count(*) from r1;', 2);
Alter table r1 set with (reshuffle);
Select count(*) from r1;
Select select_on_segment('Select count(*) from r1;', 2);
drop table r1;

-- table with update triggers on distributed key column
CREATE OR REPLACE FUNCTION trigger_func() RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
	RAISE NOTICE ''trigger_func(%) called: action = %, when = %, level = %'', TG_ARGV[0], TG_OP, TG_WHEN, TG_LEVEL;
	RETURN NULL;
END;';

set gp_create_table_any_numsegments to 2;
CREATE TABLE table_with_update_trigger(a int, b int, c int) :options;
insert into table_with_update_trigger select i,i,0 from generate_series(1,100) I;
select gp_segment_id, count(*) from table_with_update_trigger group by 1 order by 1;

CREATE TRIGGER foo_br_trigger BEFORE INSERT OR UPDATE OR DELETE ON table_with_update_trigger 
FOR EACH ROW EXECUTE PROCEDURE trigger_func('before_stmt');
CREATE TRIGGER foo_ar_trigger AFTER INSERT OR UPDATE OR DELETE ON table_with_update_trigger 
FOR EACH ROW EXECUTE PROCEDURE trigger_func('before_stmt');

CREATE TRIGGER foo_bs_trigger BEFORE INSERT OR UPDATE OR DELETE ON table_with_update_trigger 
FOR EACH STATEMENT EXECUTE PROCEDURE trigger_func('before_stmt');
CREATE TRIGGER foo_as_trigger AFTER INSERT OR UPDATE OR DELETE ON table_with_update_trigger 
FOR EACH STATEMENT EXECUTE PROCEDURE trigger_func('before_stmt');

-- update should fail
update table_with_update_trigger set a = a + 1;
-- reshuffle should success and not hiting any triggers.
Alter table table_with_update_trigger set with (reshuffle);
select gp_segment_id, count(*) from table_with_update_trigger group by 1 order by 1;
