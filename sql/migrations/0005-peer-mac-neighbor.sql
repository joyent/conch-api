SELECT run_migration(5, $$

    ALTER TABLE device_neighbor ADD COLUMN peer_mac macaddr;

$$);
