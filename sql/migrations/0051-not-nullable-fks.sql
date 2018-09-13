SELECT run_migration(51, $$

    alter table workspace_datacenter_rack
        alter workspace_id set not null,
        alter datacenter_rack_id set not null;

    alter table workspace_datacenter_room
        alter workspace_id set not null,
        alter datacenter_room_id set not null;

$$);
