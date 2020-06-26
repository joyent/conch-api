SELECT run_migration(178, $$

    drop table workspace_rack;
    drop table user_workspace_role;
    drop table workspace;

$$);
