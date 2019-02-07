-- Revert conch:user-settings from pg

BEGIN;

DROP TABLE IF EXISTS user_settings;

COMMIT;
