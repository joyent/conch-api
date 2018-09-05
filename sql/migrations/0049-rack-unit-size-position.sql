SELECT run_migration(49, $$

    alter table datacenter_rack_layout rename column ru_start to rack_unit_start;
    alter table datacenter_rack_layout
        rename constraint datacenter_rack_layout_rack_id_ru_start_key
        to datacenter_rack_layout_rack_id_rack_unit_start_key;
    alter table datacenter_rack_layout
        drop constraint if exists datacenter_rack_layout_rack_id_ru_start_key1;

    alter table device_location rename column rack_unit to rack_unit_start;
    alter table device_location
        rename constraint device_location_rack_id_rack_unit_key
        to device_location_rack_id_rack_unit_start_key;


    -- this gets us the 'device_location' relationship on Conch::DB::Result::DatacenterRackLayout
    alter table device_location
        add constraint datacenter_rack_layout_rack_id_rack_unit_start_key
        foreign key (rack_id, rack_unit_start)
        references public.datacenter_rack_layout(rack_id, rack_unit_start);

$$);
