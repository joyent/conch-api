BEGIN;

    -- Add a new enclosure column and copy the (incorrectly defined as) hba
    -- data into it.
    -- Migrate the hba column to text as well. sas3ircu isn't exactly a stable
    -- interface, so let's assume it will change from numbers to emoji at some
    -- point.
    ALTER TABLE device_disk ADD COLUMN enclosure text;
    UPDATE device_disk SET enclosure = hba;
    ALTER TABLE device_disk DROP COLUMN hba;
    ALTER TABLE device_disk ADD COLUMN hba TEXT;
    UPDATE device_disk SET hba = enclosure;

COMMIT;

