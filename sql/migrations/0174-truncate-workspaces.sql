SELECT run_migration(174, $$

    drop trigger all_racks_in_global_workspace on rack;
    drop function add_rack_to_global_workspace;

    create table legacy_workspace_rack ( like workspace_rack including all );
    create table legacy_user_workspace_role ( like user_workspace_role including all );
    create table legacy_workspace ( like workspace including all );

    insert into legacy_workspace_rack (select * from workspace_rack );
    insert into legacy_user_workspace_role (select * from user_workspace_role );
    insert into legacy_workspace (select * from workspace );

    truncate workspace_rack;
    truncate user_workspace_role;
    -- avoid "cannot truncate a table referenced in a foreign key constraint"
    delete from workspace;

$$);
