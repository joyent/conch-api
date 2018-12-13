SELECT run_migration(75, $$

    -- Rename ssd_num and friends.
    ALTER TABLE hardware_product_profile RENAME COLUMN ssd_num TO sata_ssd_num;
    ALTER TABLE hardware_product_profile RENAME COLUMN ssd_size TO sata_ssd_size;
    ALTER TABLE hardware_product_profile RENAME COLUMN ssd_slots TO sata_ssd_slots;

$$);
