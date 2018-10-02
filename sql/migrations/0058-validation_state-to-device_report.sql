SELECT run_migration(58, $$

    create index datacenter_rack_datacenter_room_id_idx on datacenter_rack (datacenter_room_id);
    create index datacenter_rack_datacenter_rack_role_id_idx on datacenter_rack (datacenter_rack_role_id);
    create index datacenter_rack_layout_rack_id_idx on datacenter_rack_layout (rack_id);
    create index datacenter_room_datacenter_id_idx on datacenter_room (datacenter_id);
    create index device_hostname_idx on device (hostname);
    create index device_hardware_product_id_idx on device (hardware_product_id);
    create index device_disk_device_id_idx on device_disk (device_id);
    create index device_location_device_id_idx on device_location (device_id);
    create index device_log_device_id_idx on device_log (device_id);
    create index device_memory_device_id_idx on device_memory (device_id);
    create index device_nic_device_id_idx on device_nic (device_id);
    create index device_nic_iface_name_idx on device_nic (iface_name);
    create index device_nic_ipaddr_idx on device_nic (ipaddr);
    create index device_report_device_id_idx on device_report (device_id);
    create index device_spec_hardware_product_id_idx on device_spec (hardware_product_id);

    create index hardware_product_hardware_vendor_id_idx on hardware_product (hardware_vendor_id);
    create index hardware_product_profile_zpool_id_idx on hardware_product_profile (zpool_id);
    create index hardware_profile_setting_hardware_product_profile_id_idx on hardware_profile_setting (hardware_product_profile_id);

    create index validation_plan_member_validation_plan_id_idx on validation_plan_member (validation_plan_id);
    create index validation_state_device_id_idx on validation_state (device_id);
    create index validation_state_validation_plan_id_idx on validation_state (validation_plan_id);
    create index workspace_parent_workspace_id_idx on workspace (parent_workspace_id);

    alter table hardware_product add constraint hardware_product_alias_key unique (alias);

$$);
