SELECT run_migration(109, $$

    alter table device rename column id to serial_number;
    alter table device add column id uuid default gen_random_uuid() not null;
    alter table device add constraint device_serial_number_key unique (serial_number);

    -- remove all references to device_pkey...
    alter table device_disk drop constraint device_disk_device_id_fkey;
    alter table device_nic drop constraint device_nic_device_id_fkey;
    alter table device_report drop constraint device_report_device_id_fkey;
    alter table device_setting drop constraint device_setting_device_id_fkey;
    alter table validation_result drop constraint validation_result_device_id_fkey;
    alter table validation_state drop constraint validation_state_device_id_fkey;
    alter table device_environment drop constraint device_environment_device_id_fkey;
    alter table device_location drop constraint device_location_device_id_fkey;
    alter table device_relay_connection drop constraint device_relay_connection_device_id_fkey;

    drop index if exists device_id_idx;
    alter table device drop constraint device_pkey;
    alter table device add primary key (id);

    -- now we fix all the tables with device_id...

    -- tables where device_id was not the PK:

    alter table device_disk rename column device_id to device_serial_number;
    alter table device_disk add column device_id uuid;
    update device_disk
        set device_id = device.id
        from device
        where device.serial_number = device_disk.device_serial_number;
    alter table device_disk drop column device_serial_number;
    alter table device_disk alter device_id set not null;
    create index device_disk_device_id_idx on device_disk (device_id);
    alter table device_disk
        add constraint device_disk_device_id_fkey foreign key (device_id) references device(id);

    alter table device_nic rename column device_id to device_serial_number;
    alter table device_nic add column device_id uuid;
    update device_nic
        set device_id = device.id
        from device
        where device.serial_number = device_nic.device_serial_number;
    alter table device_nic drop column device_serial_number;
    alter table device_nic alter device_id set not null;
    create index device_nic_device_id_idx on device_nic (device_id);
    alter table device_nic
        add constraint device_nic_device_id_fkey foreign key (device_id) references device(id);
    create unique index device_nic_device_id_iface_name_key on device_nic
        (device_id, iface_name) where (deactivated is null);

    alter table device_report rename column device_id to device_serial_number;
    alter table device_report add column device_id uuid;
    update device_report
        set device_id = device.id
        from device
        where device.serial_number = device_report.device_serial_number;
    alter table device_report drop column device_serial_number;
    alter table device_report alter device_id set not null;
    create index device_report_device_id_idx on device_report (device_id);
    alter table device_report
        add constraint device_report_device_id_fkey foreign key (device_id) references device(id);
    create index device_report_device_id_created_idx on device_report (device_id, created desc);

    alter table device_setting rename column device_id to device_serial_number;
    alter table device_setting add column device_id uuid;
    update device_setting
        set device_id = device.id
        from device
        where device.serial_number = device_setting.device_serial_number;
    alter table device_setting drop column device_serial_number;
    alter table device_setting alter device_id set not null;
    create index device_setting_device_id_idx on device_setting (device_id);
    alter table device_setting
        add constraint device_setting_device_id_fkey foreign key (device_id) references device(id);
    create unique index device_setting_device_id_name_idx on device_setting
       (device_id, name) where (deactivated is null);

    alter table validation_result rename column device_id to device_serial_number;
    alter table validation_result add column device_id uuid;
    update validation_result
        set device_id = device.id
        from device
        where device.serial_number = validation_result.device_serial_number;
    alter table validation_result drop column device_serial_number;
    alter table validation_result alter device_id set not null;
    create index validation_result_device_id_idx on validation_result (device_id);
    alter table validation_result
        add constraint validation_result_device_id_fkey foreign key (device_id) references device(id);

    alter table validation_state rename column device_id to device_serial_number;
    alter table validation_state add column device_id uuid;
    update validation_state
        set device_id = device.id
        from device
        where device.serial_number = validation_state.device_serial_number;
    alter table validation_state drop column device_serial_number;
    alter table validation_state alter device_id set not null;
    create index validation_state_device_id_idx on validation_state (device_id);
    alter table validation_state
        add constraint validation_state_device_id_fkey foreign key (device_id) references device(id);
    create index validation_state_device_id_validation_plan_id_completed_idx on validation_state (device_id, validation_plan_id, completed desc);

    -- tables where device_id was the PK or part of the PK:

    alter table device_environment rename column device_id to device_serial_number;
    alter table device_environment add column device_id uuid;
    update device_environment
        set device_id = device.id
        from device
        where device.serial_number = device_environment.device_serial_number;
    alter table device_environment
        drop column device_serial_number,
        add primary key (device_id);
    alter table device_environment
        add constraint device_environment_device_id_fkey foreign key (device_id) references device(id);

    alter table device_location rename column device_id to device_serial_number;
    alter table device_location add column device_id uuid;
    update device_location
        set device_id = device.id
        from device
        where device.serial_number = device_location.device_serial_number;
    alter table device_location
        drop column device_serial_number,
        add primary key (device_id);
    alter table device_location
        add constraint device_location_device_id_fkey foreign key (device_id) references device(id);

    alter table device_relay_connection rename column device_id to device_serial_number;
    alter table device_relay_connection add column device_id uuid;
    update device_relay_connection
        set device_id = device.id
        from device
        where device.serial_number = device_relay_connection.device_serial_number;
    alter table device_relay_connection
        drop column device_serial_number,
        add primary key (device_id, relay_id);
    create index device_relay_connection_device_id_idx on device_relay_connection (device_id);
    alter table device_relay_connection
        add constraint device_relay_connection_device_id_fkey foreign key (device_id)
            references device(id);

$$);
