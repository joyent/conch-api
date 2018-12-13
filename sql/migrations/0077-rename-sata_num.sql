SELECT run_migration(77, $$

    -- Rename sata_num and friends.
    ALTER TABLE hardware_product_profile RENAME COLUMN sata_num TO sata_hdd_num;
    ALTER TABLE hardware_product_profile RENAME COLUMN sata_size TO sata_hdd_size;
    ALTER TABLE hardware_product_profile RENAME COLUMN sata_slots TO sata_hdd_slots;

$$);
