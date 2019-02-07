-- Revert conch:workspace-devices-fn from pg

BEGIN;

DROP FUNCTION IF EXISTS workspace_devices();

COMMIT;
