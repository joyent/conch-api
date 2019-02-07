-- The purpose of this migration is to loosen the restrictions on
-- 'device_setting'. It /may/ have a relationship to a value in
-- 'hardware_profile_settings', but is not required. It keeps its own copy of
-- the 'name' column.
BEGIN;

    ALTER TABLE device_settings ADD COLUMN name text;

    UPDATE device_settings SET name = (
        SELECT name FROM hardware_profile_settings
        WHERE device_settings.resource_id = hardware_profile_settings.id
    );

    ALTER TABLE device_settings ALTER COLUMN resource_id DROP NOT NULL;

    ALTER TABLE device_settings ALTER COLUMN name SET NOT NULL;

    ALTER TABLE device_settings ADD constraint
        device_name_deactivated_unique
        UNIQUE (device_id, name, deactivated);

COMMIT;
