BEGIN;

    -- remove all redundant user_workspace_role entries for global admins.
    -- other redundant rows can be cleaned with the `clean_permissions` command.
    -- in the staging db, this accounts for 79 redundant rows.
    delete from user_workspace_role
        using user_account, workspace
        where
            user_account.is_admin is true and workspace.name != 'GLOBAL'
            and user_account.id = user_workspace_role.user_id
            and user_workspace_role.workspace_id = workspace.id;

COMMIT;
