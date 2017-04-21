INSERT INTO hardware_product_profile ( product_id, purpose, bios_firmware, cpu_num, cpu_type,
            dimms_num, ram_total, nics_num, sas_num, sas_size, ssd_num, ssd_size, ssd_slots, psu_total )
       VALUES (  ( SELECT id FROM hardware_product WHERE name = 'Joyent-Storage-Platform-7001' ),
            'Manta Object Store', 'American Megatrends Inc. 2.0a', 2, 'Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz',
            16, 516929, 7, 35, 7452.04, 1, 93.16, '0', 2 );

INSERT INTO hardware_product_profile ( product_id, purpose, bios_firmware, cpu_num, cpu_type,
            dimms_num, ram_total, nics_num, sas_num, sas_size, ssd_num, ssd_size, ssd_slots, psu_total )
       VALUES (  ( SELECT id FROM hardware_product WHERE name = 'Joyent-Storage-Platform-7201' ),
            'Mass Storage', 'American Megatrends Inc. 2.0a', 2, 'Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz',
            16, 516929, 7, 35, 7452.04, 1, 93.16, '0', 2 );

INSERT INTO hardware_product_profile ( product_id, purpose, bios_firmware, cpu_num, cpu_type,
            dimms_num, ram_total, nics_num, sas_num, sas_size, ssd_num, ssd_size, ssd_slots, psu_total )
      VALUES (  ( SELECT id FROM hardware_product WHERE name = 'Joyent-Compute-Platform-3301' ),
            'General Compute', 'Dell Inc. 2.2.5', 2, 'Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz',
            16, 258372, 7, 15, 1117.81, 1, 93.16, '0', 2 );

INSERT INTO hardware_product_profile ( product_id, purpose, bios_firmware, cpu_num, cpu_type,
            dimms_num, ram_total, nics_num, sas_num, ssd_num, ssd_size, ssd_slots, psu_total )
      VALUES (  ( SELECT id FROM hardware_product WHERE name = 'Joyent-Compute-Platform-3302' ),
            'SSD Compute', 'Dell Inc. 2.2.5', 2, 'Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz',
            0, 16, 258372, 7, 16, 1490.42, '0-15', 2 );

INSERT INTO hardware_product_profile ( product_id, purpose, bios_firmware, cpu_num, cpu_type,
            dimms_num, ram_total, nics_num, sas_num, sas_size, ssd_num, ssd_size, ssd_slots, psu_total )
      VALUES (  ( SELECT id FROM hardware_product WHERE name = 'CERES' ),
            'CPG Compute', 'Dell Inc. 2.2.5', 2, 'Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz',
            16, 258372, 7, 15, 1117.81, 1, 93.16, '0', 2 );
