BEGIN;

CREATE TABLE IF NOT EXISTS migration (
    id        serial        PRIMARY KEY,
    created   timestamptz   DEFAULT current_timestamp
);

-- Execute via `SELECT run_migration($migration_number, $$ ... $$);
CREATE OR REPLACE FUNCTION run_migration(INTEGER, TEXT)
RETURNS VOID AS
$BODY$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM migration WHERE id = $1) THEN
        EXECUTE $2;
        INSERT INTO migration (id) VALUES ($1);
        RAISE LOG 'Migration % completed.', $1;
    END IF;
END;
$BODY$ LANGUAGE plpgsql;

COMMIT;
