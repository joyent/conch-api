SELECT run_migration(69, $$

    -- Add a new nvme_num column.
    ALTER TABLE hardware_product_profile ADD COLUMN raid_num integer;

$$);
