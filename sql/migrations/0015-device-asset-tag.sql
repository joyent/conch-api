SELECT run_migration(15, $$

    -- Add asset tag column
    ALTER TABLE device ADD COLUMN asset_tag text;

$$);

