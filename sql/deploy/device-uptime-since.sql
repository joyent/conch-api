BEGIN;

    ALTER TABLE device ADD COLUMN uptime_since timestamptz;

COMMIT;
