BEGIN;

    create index device_settings_device_id_idx on device_settings (device_id);

COMMIT;
