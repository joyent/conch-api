SELECT run_migration(125, $$

    delete from user_workspace_role
        using user_account
        where user_account.is_admin is true;

$$);
