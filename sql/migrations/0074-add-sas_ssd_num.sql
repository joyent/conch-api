SELECT run_migration(74, $$

    -- Add a new sas_ssd_num and friends.
    ALTER TABLE hardware_product_profile ADD COLUMN sas_ssd_num integer;
    ALTER TABLE hardware_product_profile ADD COLUMN sas_ssd_size integer;
    ALTER TABLE hardware_product_profile ADD COLUMN sas_ssd_slots text;

$$);
