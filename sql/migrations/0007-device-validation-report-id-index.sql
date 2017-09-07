SELECT run_migration(7, $$

    CREATE INDEX ON device_validate (report_id);

$$);
