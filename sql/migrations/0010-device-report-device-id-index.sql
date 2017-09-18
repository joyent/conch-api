SELECT run_migration(10, $$

    CREATE INDEX ON device_report (device_id);

$$);

