SELECT run_migration(123, $$

    drop index device_serial_number_idx;
    -- drop index device_serial_number_key;
    alter table device add constraint device_serial_number_key
        unique (serial_number) deferrable initially immediate;

$$);
