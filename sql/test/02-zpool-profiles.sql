
INSERT INTO zpool_profile (name, vdev_t, vdev_n, disk_per, spare, log, cache)
       VALUES ( '2-ssds-1-cpu', 'mirror', 7, 2, 1, 1, 0 );

INSERT INTO zpool_profile (name, vdev_t, vdev_n, disk_per, spare, log, cache)
       VALUES ( '65-ssds-2-cpu', 'raidz2', 3, 11, 2, 1, 0 );

UPDATE hardware_product_profile
    SET zpool_id =
        ( SELECT id FROM zpool_profile WHERE name = '2-ssds-1-cpu' )
    WHERE hardware_product_id =
        ( SELECT id FROM hardware_product WHERE name = '2-ssds-1-cpu' );

UPDATE hardware_product_profile
    SET zpool_id =
        ( SELECT id FROM zpool_profile WHERE name = '65-ssds-2-cpu' )
    WHERE hardware_product_id =
        ( SELECT id FROM hardware_product WHERE name = '65-ssds-2-cpu' );

