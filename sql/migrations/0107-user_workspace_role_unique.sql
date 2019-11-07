SELECT run_migration(107, $$

    -- this constraint serves no purpose. the primary key already covers this.
    alter table user_workspace_role drop constraint if exists user_workspace_role_user_id_workspace_id_role_key;

$$);
