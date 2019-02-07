BEGIN;

    -- remove all user_workspace_role rows for deactivated users
    delete from user_workspace_role
        using user_account
        where user_account.deactivated is not null
        and user_account.id = user_workspace_role.user_id;

COMMIT;
