BEGIN;

    create type user_workspace_role_enum as enum ('ro', 'rw', 'admin');

    alter table user_workspace_role add column role user_workspace_role_enum not null default 'ro';

    update user_workspace_role
        set role =
            case
                when role.name = 'Administrator' then 'admin'::user_workspace_role_enum
                when role.name = 'Read-only' then 'ro'::user_workspace_role_enum
                when role.name = 'Integrator' then 'rw'::user_workspace_role_enum
                when role.name = 'DC Operations' then 'rw'::user_workspace_role_enum
                when role.name = 'Integrator Manager' then 'rw'::user_workspace_role_enum
            end
        from role
        where user_workspace_role.role_id = role.id;

    alter table user_workspace_role drop column role_id;
    drop table role;

COMMIT;
