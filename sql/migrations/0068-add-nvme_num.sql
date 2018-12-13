SELECT run_migration(68, $$

    -- Add a new nvme_num column.
    ALTER TABLE hardware_product_profile ADD COLUMN nvme_num integer;

$$);
