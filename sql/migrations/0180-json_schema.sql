SELECT run_migration(180, $$

  create table json_schema (
    id uuid default gen_random_uuid() not null primary key,
    type text not null,
    name text not null,
    version integer not null check (version > 0),
    body jsonb not null,
    created timestamp with time zone default now() not null,
    created_user_id uuid not null references user_account (id),
    deactivated timestamp with time zone,

    unique (type, name, version)
  );
  create index json_schema_type_idx on json_schema (type) where deactivated is null;
  create index json_schema_type_name_idx on json_schema (type, name) where deactivated is null;

  grant select on all tables in schema public to conch_read_only;

$$);
