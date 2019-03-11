SELECT run_migration(86, $$

    create unique index datacenter_room_alias_key on datacenter_room (alias);

$$);
