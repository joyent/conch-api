SELECT run_migration(127, $$

    alter table device_setting
        alter column value type text,
        alter column value set not null;

    alter table user_setting
        alter column value type text,
        alter column value set not null;

$$);
