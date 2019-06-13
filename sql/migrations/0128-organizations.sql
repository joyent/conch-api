SELECT run_migration(128, $$

    alter type user_workspace_role_enum rename to role_enum;

    create table organization (
        id uuid default gen_random_uuid() not null primary key,
        name text not null,
        description text,
        created timestamp with time zone default now() not null,
        deactivated timestamp with time zone
    );
    create unique index organization_name_key
        on organization (name) where deactivated is null;

    create table user_organization_role (
        user_id uuid not null references user_account (id),
        organization_id uuid not null references organization (id),
        role role_enum default 'ro' not null,
        primary key (user_id, organization_id)
    );

    create table organization_workspace_role (
        organization_id uuid not null references organization (id),
        workspace_id uuid not null references workspace (id),
        role role_enum default 'ro' not null,
        primary key (organization_id, workspace_id)
    );

    grant select on all tables in schema public to conch_read_only;

$$);
