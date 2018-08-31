SELECT run_migration(44, $$

    alter table device_nic
        add column state text,
        add column speed text,
        add column ipaddr inet,
        add column mtu integer;

    update device_nic
        set
            state = device_nic_state.state,
            speed = device_nic_state.speed,
            ipaddr = device_nic_state.ipaddr,
            mtu = device_nic_state.mtu
        from device_nic_state
        where device_nic.mac = device_nic_state.mac;

    drop table device_nic_state;

$$);
