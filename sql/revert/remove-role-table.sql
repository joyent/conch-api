-- Revert conch:remove-role-table from pg

BEGIN;

DO $$
BEGIN

    RAISE NOTICE 'Cannot safely rollback user_workspace_role removal, just making a mess instead.';

    alter table user_workspace_role drop column if exists role;

    drop type user_workspace_role_enum;

END $$;

COMMIT;
