SELECT run_migration(40, $$

    alter table device rename column hardware_product to hardware_product_id;
    alter table device rename column role to device_role_id;
    alter table datacenter_rack rename column role to datacenter_rack_role_id;

    drop function workspace_devices(uuid);

$$);
