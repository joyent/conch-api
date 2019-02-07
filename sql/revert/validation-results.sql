-- Revert conch:validation-results from pg

BEGIN;

DROP TABLE IF EXISTS validation_state_member;
DROP TABLE IF EXISTS validation_result;

COMMIT;
