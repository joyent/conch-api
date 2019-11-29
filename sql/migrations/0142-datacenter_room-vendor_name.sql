SELECT run_migration(142, $$

    alter table datacenter_room drop constraint if exists datacenter_room_vendor_name_key;
    alter table datacenter_room alter column vendor_name set not null;
    alter table datacenter_room add constraint datacenter_room_vendor_name_key unique (vendor_name);

$$);
