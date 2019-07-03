SELECT run_migration(108, $$

    alter table relay rename column id to serial_number;
    alter table relay rename column alias to name;
    alter table relay add column id uuid default gen_random_uuid() not null;
    alter table relay add constraint relay_serial_number_key unique (serial_number);

    alter table device_relay_connection rename column relay_id to relay_serial_number;
    alter table device_relay_connection add column relay_id uuid;
    update device_relay_connection
        set relay_id = relay.id
        from relay
        where relay.serial_number = device_relay_connection.relay_serial_number;
    alter table device_relay_connection
        drop column relay_serial_number,
        -- commented out constraints/indexes drop off on their own
        -- drop constraint device_relay_connection_pkey,
        -- drop constraint device_relay_connection_relay_id_fkey,
        add primary key (device_id, relay_id);

    -- drop index device_relay_connection_relay_id_idx;
    create index device_relay_connection_relay_id_idx on device_relay_connection (relay_id);


    alter table user_relay_connection rename column relay_id to relay_serial_number;
    alter table user_relay_connection add column relay_id uuid;
    update user_relay_connection
        set relay_id = relay.id
        from relay
        where relay.serial_number = user_relay_connection.relay_serial_number;
    alter table user_relay_connection
        drop column relay_serial_number,
        -- drop constraint user_relay_connection_pkey,
        -- drop constraint user_relay_connection_relay_id_fkey,
        add primary key (user_id, relay_id);

    -- drop index user_relay_connection_relay_id_idx;
    create index user_relay_connection_relay_id_idx on user_relay_connection (relay_id);

    alter table relay drop constraint relay_pkey;
    alter table relay add primary key (id);

    alter table device_relay_connection
        add constraint device_relay_connection_relay_id_fkey foreign key (relay_id)
            references relay(id);

    alter table user_relay_connection
        add constraint user_relay_connection_relay_id_fkey foreign key (relay_id)
            references relay(id);

$$);
