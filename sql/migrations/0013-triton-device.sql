SELECT run_migration(13, $$

-- Clean up unused tables
DROP TABLE device_notes;
DROP TABLE hardware_totals;
DROP TABLE zpool_attributes;

DROP TABLE triton_post_setup_log;
DROP TABLE triton_post_setup;
DROP TABLE triton_post_setup_stage;
DROP TABLE triton;

-- Clean up unused column
ALTER TABLE device DROP COLUMN boot_phase;

ALTER TABLE device ADD COLUMN latest_triton_reboot TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE device ADD COLUMN triton_uuid UUID DEFAULT NULL;

$$);
