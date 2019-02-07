-- Revert conch:orchestration from pg

BEGIN;

DROP TABLE IF EXISTS workflow;
DROP TYPE IF EXISTS e_workflow_status;
DROP TABLE IF EXISTS workflow_status;
DROP TABLE IF EXISTS workflow_step;
DROP TYPE IF EXISTS e_workflow_step_state;
DROP TYPE IF EXISTS e_workflow_validation_status;
DROP TABLE IF EXISTS workflow_step_status;

COMMIT;
