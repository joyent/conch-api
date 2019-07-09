SELECT run_migration(124, $$

    alter table datacenter add constraint datacenter_vendor_region_location_key
        unique (vendor, region, location);

$$);
