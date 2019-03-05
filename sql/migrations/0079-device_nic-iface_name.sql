SELECT run_migration(79, $$

    create unique index device_nic_device_id_iface_name_key
        on device_nic (device_id, iface_name) where deactivated is null;

$$);
