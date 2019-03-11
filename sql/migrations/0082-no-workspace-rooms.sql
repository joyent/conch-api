SELECT run_migration(82, $$

    -- all new racks will be added to the GLOBAL workspace
    create function add_rack_to_global_workspace() returns trigger language plpgsql as $PROC$
      begin
        insert into workspace_rack (workspace_id, rack_id)
            select workspace.id, NEW.id
            from workspace
            where workspace.name = 'GLOBAL'
            on conflict (workspace_id, rack_id) do nothing;
        return NEW;
      end;
      $PROC$;

    create trigger all_racks_in_global_workspace after insert on rack
        for each row execute procedure add_rack_to_global_workspace();

    -- associate all racks with the GLOBAL workspace
    insert into workspace_rack (workspace_id, rack_id)
        select * from
            (select id as workspace_id from workspace where name = 'GLOBAL') w,
            (select id as rack_id from rack r) r
        on conflict do nothing;

    -- copy all racks into the workspace(s) that its room was in
    insert into workspace_rack (workspace_id, rack_id)
        select workspace_datacenter_room.workspace_id, rack.id
            from workspace_datacenter_room
            inner join rack on workspace_datacenter_room.datacenter_room_id = rack.datacenter_room_id
        on conflict do nothing;

    drop trigger all_rooms_in_global_workspace on datacenter_room;
    drop function add_room_to_global_workspace();

    drop table workspace_datacenter_room;

$$);
