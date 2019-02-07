-- Revert conch:validation-system from pg

BEGIN;

DROP TABLE IF EXISTS validation_state;
DROP TYPE IF EXISTS validation_status_enum;
DROP TABLE IF EXISTS validation_plan_member;
DROP TABLE IF EXISTS validation_plan;
DROP TABLE IF EXISTS validation;

COMMIT;
