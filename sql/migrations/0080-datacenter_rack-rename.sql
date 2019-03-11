SELECT run_migration(80, $$

    alter table datacenter_rack rename to rack;
    alter table rack rename column datacenter_rack_role_id to rack_role_id;
    alter table rack rename constraint datacenter_rack_pkey to rack_pkey;
    alter table rack rename constraint datacenter_rack_datacenter_room_id_fkey to rack_datacenter_room_id_fkey;
    alter table rack rename constraint datacenter_rack_role_fkey to rack_role_fkey;
    alter index datacenter_rack_datacenter_rack_role_id_idx rename to rack_rack_role_id_idx;
    alter index datacenter_rack_datacenter_room_id_idx rename to rack_datacenter_room_id_idx;

    alter table workspace_datacenter_rack rename to workspace_rack;
    alter table workspace_rack rename column datacenter_rack_id to rack_id;
    alter table workspace_rack rename constraint workspace_datacenter_rack_pkey to workspace_rack_pkey;
    alter table workspace_rack rename constraint workspace_datacenter_rack_datacenter_rack_id_fkey to workspace_rack_rack_id_fkey;
    alter table workspace_rack rename constraint workspace_datacenter_rack_workspace_id_fkey to workspace_rack_workspace_id_fkey;
    alter index workspace_datacenter_rack_workspace_id_idx rename to workspace_rack_workspace_id_idx;
    alter index workspace_datacenter_rack_datacenter_rack_id_idx rename to workspace_rack_rack_id_idx;

    alter table datacenter_rack_role rename to rack_role;
    alter table rack_role rename constraint datacenter_rack_role_pkey to rack_role_pkey;
    alter table rack_role rename constraint datacenter_rack_role_name_key to rack_role_name_key;
    alter table rack_role rename constraint datacenter_rack_role_name_rack_size_key to rack_role_name_rack_size_key;

    alter table datacenter_rack_layout rename to rack_layout;
    alter table rack_layout rename constraint datacenter_rack_layout_pkey to rack_layout_pkey;
    alter table rack_layout rename constraint datacenter_rack_layout_rack_id_rack_unit_start_key to rack_layout_rack_id_rack_unit_start_key;
    alter table rack_layout rename constraint datacenter_rack_layout_product_id_fkey to rack_layout_hardware_product_id_fkey;
    alter table rack_layout rename constraint datacenter_rack_layout_rack_id_fkey to rack_layout_rack_id_fkey;
    alter index datacenter_rack_layout_hardware_product_id_idx rename to rack_layout_hardware_product_id_idx;
    alter index datacenter_rack_layout_rack_id_idx rename to rack_layout_rack_id_idx;

    alter table device_location rename constraint datacenter_rack_layout_rack_id_rack_unit_start_key to rack_layout_rack_id_rack_unit_start_key;

$$);
