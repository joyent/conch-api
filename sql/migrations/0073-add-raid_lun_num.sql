SELECT run_migration(73, $$

    -- Add a new raid_lun_num column.
    ALTER TABLE hardware_product_profile ADD COLUMN raid_lun_num integer;

$$);
