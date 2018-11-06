\set options 'with (appendonly = true)'

drop schema if exists test_reshuffle_ao;
create schema test_reshuffle_ao;
set search_path='test_reshuffle_ao';

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
set gp_create_table_any_numsegments to 1;
Create table r1(a int, b int, c int) :options distributed replicated;
insert into r1 select i,i,0 from generate_series(1,100) I;
Select count(*) from r1;
Alter table r1 set with (reshuffle);
Select count(*) from r1;
drop table r1;

set gp_create_table_any_numsegments to 2;
Create table r1(a int, b int, c int) :options distributed replicated;
insert into r1 select i,i,0 from generate_series(1,100) I;
Select count(*) from r1;
Alter table r1 set with (reshuffle);
Select count(*) from r1;
drop table r1;
