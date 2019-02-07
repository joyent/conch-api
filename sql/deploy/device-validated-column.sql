BEGIN;

    ALTER TABLE device ADD COLUMN validated timestamptz;

COMMIT;

