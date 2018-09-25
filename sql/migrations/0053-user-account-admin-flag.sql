SELECT run_migration(53, $$

    alter table user_account add column is_admin boolean default false not null;

    -- set user_account.is_admin for all current GLOBAL admins
    update user_account
        set is_admin = true
        from user_workspace_role
        join workspace on user_workspace_role.workspace_id = workspace.id
        where
            user_account.id = user_workspace_role.user_id
            and workspace.name = 'GLOBAL'
            and user_workspace_role.role = 'admin';

$$);
