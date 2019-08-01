SELECT run_migration(128, $$

    alter type user_workspace_role_enum rename to role_enum;

$$);
