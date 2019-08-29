SELECT run_migration(114, $$

    delete from device_report where invalid_report is not null;

    alter table device_report
        drop column invalid_report,
        alter column report set not null;

$$);
