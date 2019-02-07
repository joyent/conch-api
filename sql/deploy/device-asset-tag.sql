BEGIN;

    -- Add asset tag column
    ALTER TABLE device ADD COLUMN asset_tag text;

COMMIT;

