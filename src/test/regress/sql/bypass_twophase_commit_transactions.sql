-- start_ignore
BEGIN;
DROP TABLE IF EXISTS bypass_twophase_commit;
CREATE TABLE bypass_twophase_commit(a int) DISTRIBUTED BY (a);
COMMIT;
-- end_ignore

--
-- No two phase commit because no writing on QE
--
BEGIN;
SET debug_dtm_action_segment=1;
SET debug_dtm_action = "fail_begin_command";
SET debug_dtm_action_target = "protocol";
SET debug_dtm_action_protocol = "prepare";
SELECT * FROM bypass_twophase_commit;
COMMIT;
RESET debug_dtm_action;
RESET debug_dtm_action_target;
RESET debug_dtm_action_protocol;

--
-- Two phase commit occur because there is writing on QE
--
BEGIN;
SET debug_dtm_action_segment=1;
SET debug_dtm_action = "fail_begin_command";
SET debug_dtm_action_target = "protocol";
SET debug_dtm_action_protocol = "prepare";
INSERT INTO bypass_twophase_commit SELECT generate_series(1,10);
COMMIT;
RESET debug_dtm_action;
RESET debug_dtm_action_target;
RESET debug_dtm_action_protocol;

--
-- No two phase commit because there is no change on QE
--
INSERT INTO bypass_twophase_commit SELECT generate_series(1,10);

BEGIN;
SET debug_dtm_action_segment=1;
SET debug_dtm_action = "fail_begin_command";
SET debug_dtm_action_target = "protocol";
SET debug_dtm_action_protocol = "prepare";
UPDATE bypass_twophase_commit SET a = 0 WHERE a = 100;
COMMIT;
RESET debug_dtm_action;
RESET debug_dtm_action_target;
RESET debug_dtm_action_protocol;
