SELECT run_migration(94, $$

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

    alter table user_workspace_role drop constraint user_workspace_role_user_id_workspace_id_role_key;

$$);
