SELECT run_migration(116, $$

    alter table device_disk drop column temp;

$$);
