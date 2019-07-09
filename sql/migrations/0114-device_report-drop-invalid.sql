SELECT run_migration(114, $$

    alter table device_report drop column invalid_report;

$$);
