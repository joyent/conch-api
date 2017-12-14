SELECT run_migration(18, $$

    ALTER TABLE device ADD COLUMN triton_setup timestamptz;

$$);
