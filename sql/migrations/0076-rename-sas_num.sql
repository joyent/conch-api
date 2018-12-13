SELECT run_migration(76, $$

    -- Rename sas_num and friends.
    ALTER TABLE hardware_product_profile RENAME COLUMN sas_num TO sas_hdd_num;
    ALTER TABLE hardware_product_profile RENAME COLUMN sas_size TO sas_hdd_size;
    ALTER TABLE hardware_product_profile RENAME COLUMN sas_slots TO sas_hdd_slots;

$$);
