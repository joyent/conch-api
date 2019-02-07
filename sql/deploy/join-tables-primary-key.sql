BEGIN;

    alter table user_workspace_role add constraint
        user_workspace_role_pkey primary key (user_id, workspace_id);
    alter table user_workspace_role add constraint
        user_workspace_role_user_id_workspace_id_role_key unique (user_id, workspace_id, role);
    alter table user_workspace_role drop constraint user_workspace_role_user_id_workspace_id_key;
    create index user_workspace_role_workspace_id_idx on user_workspace_role (workspace_id);

    alter table workspace_datacenter_rack add constraint
        workspace_datacenter_rack_pkey primary key (workspace_id, datacenter_rack_id);
    alter table workspace_datacenter_rack drop constraint
        workspace_datacenter_rack_workspace_id_datacenter_rack_id_key;
    create index workspace_datacenter_rack_workspace_id_idx on
        workspace_datacenter_rack (workspace_id);
    create index workspace_datacenter_rack_datacenter_rack_id_idx on
        workspace_datacenter_rack (datacenter_rack_id);

    alter table workspace_datacenter_room add constraint
        workspace_datacenter_room_pkey primary key (workspace_id, datacenter_room_id);
    alter table workspace_datacenter_room drop constraint
        workspace_datacenter_room_workspace_id_datacenter_room_id_key;
    -- this already exists
    -- create index workspace_datacenter_room_workspace_id_idx on
    --     workspace_datacenter_room (workspace_id);
    create index workspace_datacenter_room_datacenter_room_id_idx on
        workspace_datacenter_room (datacenter_room_id);

COMMIT;
