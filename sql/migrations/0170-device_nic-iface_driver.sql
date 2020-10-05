SELECT run_migration(170, $$

    alter table device_nic drop column iface_driver;

$$);
