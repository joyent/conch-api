-- Revert conch:user-device_settings from pg

BEGIN;

alter table user_setting rename to user_settings;
alter table device_setting rename to device_settings;

COMMIT;
