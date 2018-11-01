SELECT run_migration(66, $$

    alter table device_report
        alter report drop not null,
        add column invalid_report text default null;

$$);
