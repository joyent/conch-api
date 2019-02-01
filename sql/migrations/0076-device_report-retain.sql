SELECT run_migration(76, $$

    alter table device_report drop column received_count;
    alter table device_report drop column last_received;
    alter table device_report add column retain boolean;

$$);
