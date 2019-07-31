SELECT run_migration(123, $$

    alter table device drop constraint device_serial_number_key;
    alter table device add constraint device_serial_number_key
        unique (serial_number) deferrable initially immediate;

    alter table device_location drop constraint device_location_rack_id_rack_unit_start_key;
    alter table device_location add constraint device_location_rack_id_rack_unit_start_key
        unique (rack_id, rack_unit_start) deferrable initially immediate;

$$);
