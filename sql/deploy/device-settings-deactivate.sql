BEGIN;

    ALTER TABLE device_settings ADD COLUMN deactivated timestamptz;

COMMIT;
