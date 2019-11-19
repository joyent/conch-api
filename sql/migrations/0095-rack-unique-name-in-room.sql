SELECT run_migration(95, $$

    alter table rack drop constraint if exists rack_datacenter_room_id_name_key;
    alter table rack add constraint rack_datacenter_room_id_name_key unique (datacenter_room_id, name);

$$);
