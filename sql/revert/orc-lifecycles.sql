-- Revert conch:orc-lifecycles from pg

BEGIN;

DROP TABLE IF EXISTS workflow_lifecycle;
DROP TABLE IF EXISTS workflow_lifecycle_plan;

COMMIT;
