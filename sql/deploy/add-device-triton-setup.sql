BEGIN;

    ALTER TABLE device ADD COLUMN triton_setup timestamptz;

COMMIT;
