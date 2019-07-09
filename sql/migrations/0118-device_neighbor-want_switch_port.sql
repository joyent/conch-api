SELECT run_migration(118, $$

    alter table device_neighbor
        drop column want_switch,
        drop column want_port;

$$);
