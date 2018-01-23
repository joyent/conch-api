INSERT INTO zpool_profile (name, vdev_t, vdev_n, disk_per, spare, log, cache)
       VALUES ( 'Joyent-Compute-Platform-3301', 'mirror', 7, 2, 1, 1, 0 );

INSERT INTO zpool_profile (name, vdev_t, vdev_n, disk_per, spare, log, cache)
       VALUES ( 'Joyent-Compute-Platform-3101', 'mirror', 7, 2, 1, 1, 0 );

INSERT INTO zpool_profile (name, vdev_t, vdev_n, disk_per, spare, log, cache)
       VALUES ( 'Joyent-Compute-Platform-3302', 'raidz2', 1, 8, 0, 0, 0 );

INSERT INTO zpool_profile (name, vdev_t, vdev_n, disk_per, spare, log, cache)
       VALUES ( 'Joyent-Compute-Platform-3302', 'raidz2', 2, 8, 0, 0, 0 );

INSERT INTO zpool_profile (name, vdev_t, vdev_n, disk_per, spare, log, cache)
       VALUES ( 'Joyent-Storage-Platform-7201', 'raidz2', 3, 11, 2, 1, 0 );

INSERT INTO zpool_profile (name, vdev_t, vdev_n, disk_per, spare, log, cache)
       VALUES ( 'Joyent-Storage-Platform-7001', 'raidz2', 3, 11, 2, 1, 0 );

INSERT INTO hardware_product_profile ( product_id, purpose, bios_firmware, cpu_num, cpu_type, 
            dimms_num, ram_total, nics_num, psu_total, rack_unit, usb_num )
       VALUES ( ( SELECT id FROM hardware_product WHERE name = 'S4048-ON' ),
            'TOR switch', '9.10(0.1P18)', 1, 'Intel Rangeley',
            1, 3, 48, 2, 1, 0
       );

INSERT INTO hardware_product_profile ( product_id, purpose, bios_firmware, cpu_num, cpu_type,
            dimms_num, ram_total, nics_num, sas_num, sas_size, ssd_num, ssd_size, ssd_slots, psu_total, zpool_id,
            rack_unit, usb_num)
       VALUES (  ( SELECT id FROM hardware_product WHERE name = 'Joyent-Storage-Platform-7001' ),
            'Manta Object Store', 'American Megatrends Inc. 2.0a', 2, 'Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz',
            16, 512, 7, 35, 7452.04, 1, 93.16, '0', 2,
            ( SELECT id FROM zpool_profile WHERE name = 'Joyent-Storage-Platform-7001' ),
            4, 1
       );

INSERT INTO hardware_product_profile ( product_id, purpose, bios_firmware, cpu_num, cpu_type,
            dimms_num, ram_total, nics_num, sas_num, sas_size, ssd_num, ssd_size, ssd_slots, psu_total, zpool_id,
            rack_unit, usb_num )
      VALUES (  ( SELECT id FROM hardware_product WHERE name = 'Joyent-Compute-Platform-3301' ),
            'General Compute', 'Dell Inc. 2.2.5', 2, 'Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz',
            16, 256, 7, 15, 1117.81, 1, 93.16, '0', 2,
            ( SELECT id FROM zpool_profile WHERE name = 'Joyent-Compute-Platform-3301' ),
            2, 1
       );

