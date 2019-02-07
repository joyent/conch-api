BEGIN;

    CREATE TABLE user_settings (
        id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id     uuid        NOT NULL REFERENCES user_account(id),
        name        text        NOT NULL,
        value       jsonb       NOT NULL,
        created     timestamptz NOT NULL DEFAULT current_timestamp,
        deactivated timestamptz
    );

    CREATE UNIQUE INDEX ON user_settings (user_id, name) WHERE deactivated IS NULL;

    -- The unique index on device_settings didn't prevent duplicate keys
    -- because `null` is always considered unique. Set up the index to match
    -- the one on user_settings
    ALTER TABLE device_settings DROP CONSTRAINT device_name_deactivated_unique;

    CREATE UNIQUE INDEX ON device_settings (device_id, name) WHERE deactivated IS NULL;

COMMIT;

