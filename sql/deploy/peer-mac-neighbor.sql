BEGIN;

    ALTER TABLE device_neighbor ADD COLUMN peer_mac macaddr;

COMMIT;
