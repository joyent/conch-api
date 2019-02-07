-- Revert conch:add-relay-to-device-and-user from pg

BEGIN;

    DROP TABLE IF EXISTS device_relay_connection;
    DROP TABLE IF EXISTS user_relay_connection;

COMMIT;
