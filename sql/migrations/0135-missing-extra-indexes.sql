SELECT run_migration(135, $$

    -- found by running dev/sql/missing-indexes.sql
    create index device_build_id_idx on device (build_id);
    create index rack_build_id_idx on rack (build_id);
    create index organization_build_role_build_id_idx on organization_build_role (build_id);
    create index organization_workspace_role_workspace_id_idx on organization_workspace_role (workspace_id);
    create index user_build_role_build_id_idx on user_build_role (build_id);
    create index user_organization_role_organization_id_idx on user_organization_role (organization_id);

    -- "Redundant Indexing in PostgreSQL: If you have a table with a column included as the first
    -- column in a multi-column index and then again with it's own index, you may be over indexing.
    -- Postgres will use the multi-column index for queries on the first column."
    -- https://www.monkeyatlarge.com/archives/2011/02/08/redundant-indexing-in-postgresql/

    drop index device_relay_connection_device_id_idx;   -- see device_relay_connection_pkey
    drop index device_report_device_id_idx;             -- see device_report_device_id_created_idx
    drop index user_relay_connection_user_id_idx;       -- see user_relay_connection_pkey
    drop index user_workspace_role_user_id_idx;         -- see user_workspace_role_pkey
    drop index validation_state_device_id_idx;          -- see validation_state_device_id_validation_plan_id_completed_idx
    drop index validation_state_member_validation_state_id_idx; -- see validation_state_member_pkey
    drop index workspace_rack_workspace_id_idx;         -- see workspace_rack_pkey

$$);
