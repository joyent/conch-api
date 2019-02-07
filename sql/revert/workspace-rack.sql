-- Revert conch:workspace-rack from pg

BEGIN;

DROP TABLE IF EXISTS workspace_datacenter_rack;

COMMIT;
