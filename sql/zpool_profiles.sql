INSERT INTO zpool_profile (name, vdev_t, vdev_n, disk_per, spare, log, cache)
       VALUES ( 'Joyent-Compute-Platform-3301', 'mirror', 7, 2, 1, 1, 0 );

INSERT INTO zpool_profile (name, vdev, disk_per, spare, log, cache)
       VALUES ( 'Joyent-Compute-Platform-3302', 'raidz2', 1, 8, 0, 0, 0 );

INSERT INTO zpool_profile (name, vdev, disk_per, spare, log, cache)
       VALUES ( 'Joyent-Compute-Platform-3302', 'raidz2', 2, 8, 0, 0, 0 );

INSERT INTO zpool_profile (name, vdev, disk_per, spare, log, cache)
       VALUES ( 'Joyent-Storage-Platform-7201', 'raidz2', 3, 11, 2, 1, 0 );

INSERT INTO zpool_profile (name, vdev, disk_per, spare, log, cache)
       VALUES ( 'Joyent-Storage-Platform-7001', 'raidz2', 3, 11, 2, 1, 0 );
