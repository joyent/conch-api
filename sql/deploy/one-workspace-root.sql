BEGIN;

    -- thanks to https://www.dbrnd.com/2017/12/postgresql-allow-single-null-for-unique-constraint-column/
    create unique index workspace_parent_id_idx on workspace
        ((parent_workspace_id is null)) where parent_workspace_id is null;

COMMIT;
