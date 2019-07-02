SELECT run_migration(105, $$

    alter table hardware_product
        add column rack_unit_size integer check (rack_unit_size > 0);

    update hardware_product
        set rack_unit_size = hardware_product_profile.rack_unit
        from hardware_product_profile
        where hardware_product_profile.hardware_product_id = hardware_product.id;

    -- for the remaining rows, use a obviously-placeholder value, to be fixed later (the large
    -- rack unit size will prevent any layouts from using this hardware without fixing)
    update hardware_product set rack_unit_size = 999 where rack_unit_size is null;

    alter table hardware_product alter rack_unit_size set not null;
    alter table hardware_product_profile drop column rack_unit;

$$);
