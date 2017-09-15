SELECT run_migration(9, $$

    ALTER TABLE device ADD COLUMN validated timestamptz;

$$);

