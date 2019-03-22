SELECT run_migration(87, $$

    update device set health = lower(health);

    create type device_health_enum as enum ('error','fail','unknown','pass');
    alter table device alter column health type device_health_enum using health::device_health_enum;

$$);
