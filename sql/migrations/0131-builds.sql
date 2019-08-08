SELECT run_migration(131, $$

    create table build (
        id uuid default gen_random_uuid() not null primary key,
        name text not null constraint build_name_key unique,
        description text,
        created timestamp with time zone default now() not null,
        started timestamp with time zone,
        completed timestamp with time zone,
        completed_user_id uuid references user_account (id)
    );

    create table user_build_role (
        user_id uuid not null references user_account (id),
        build_id uuid not null references build (id),
        role role_enum default 'ro' not null,
        primary key (user_id, build_id)
    );

    create table organization_build_role (
        organization_id uuid not null references organization (id),
        build_id uuid not null references build (id),
        role role_enum default 'ro' not null,
        primary key (organization_id, build_id)
    );

    grant select on all tables in schema public to conch_read_only;

    alter table rack add column build_id uuid default null references build (id);
    alter table device add column build_id uuid default null references build (id);

$$);
