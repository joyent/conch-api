SELECT run_migration(6, $$

    ALTER TABLE device ADD COLUMN uptime_since timestamptz;

$$);
