SELECT run_migration(52, $$

    create unique index device_settings_name_key
        on device_settings (device_id, name) where deactivated is null;

$$);
