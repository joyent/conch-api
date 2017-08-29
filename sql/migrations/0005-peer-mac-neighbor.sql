-- The purpose of this migration is to loosen the restrictions on
-- 'device_setting'. It /may/ have a relationship to a value in
-- 'hardware_profile_settings', but is not required. It keeps its own copy of
-- the 'name' column.
SELECT run_migration(5, $$

    ALTER TABLE device_neighbor ADD COLUMN peer_mac macaddr;

$$);
