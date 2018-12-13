SELECT run_migration(72, $$

    -- Add a new nvme_ssd_num and friends.
    ALTER TABLE hardware_product_profile ADD COLUMN nvme_ssd_num integer;
    ALTER TABLE hardware_product_profile ADD COLUMN nvme_ssd_size integer;
    ALTER TABLE hardware_product_profile ADD COLUMN nvme_ssd_slots text;

$$);
