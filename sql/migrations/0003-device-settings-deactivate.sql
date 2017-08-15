SELECT run_migration(3, $$

    ALTER TABLE device_settings ADD COLUMN deactivated timestamptz;

$$);
