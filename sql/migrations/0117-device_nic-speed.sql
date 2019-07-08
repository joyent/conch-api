SELECT run_migration(117, $$

    alter table device_nic drop column speed;

$$);
