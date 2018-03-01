SELECT run_migration(22, $$

    -- Set expected Dell S4048-ON FTOS version to 9.11(2.5)
    UPDATE hardware_product_profile SET bios_firmware = '9.11(2.5)'
        WHERE product_id =
        ( SELECT id FROM hardware_product WHERE name = 'S4048-ON' );

$$);
