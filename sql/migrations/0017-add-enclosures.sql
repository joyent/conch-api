SELECT run_migration(17, $$

    -- Add a new enclosure column and copy the (incorrectly defined as) hba
    -- data into it.
    ALTER TABLE device_disk ADD COLUMN enclosure INTEGER;
    UPDATE device_disk SET enclosure = hba;

$$);

