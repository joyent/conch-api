SELECT run_migration(84, $$

    alter table device_disk
        alter column hba set data type integer using hba::integer,
        alter column enclosure set data type integer using enclosure::integer;

$$);
