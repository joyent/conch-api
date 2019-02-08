-- Deploy conch:drop-run-migrations to pg

BEGIN;

DROP FUNCTION IF EXISTS run_migration(INTEGER, TEXT);
DROP TABLE IF EXISTS migration;

COMMIT;
