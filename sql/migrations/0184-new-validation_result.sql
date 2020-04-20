SELECT run_migration(184, $$

  create table validation_result (
    id uuid default gen_random_uuid() not null primary key,
    json_schema_id uuid not null references json_schema (id),
    created timestamp with time zone default now() not null,
    status validation_status_enum not null,
    data_location text,
    schema_location text,
    absolute_schema_location text,
    error text,
    constraint validation_result_all_columns_key unique (json_schema_id, status, data_location, schema_location, absolute_schema_location, error),
    check ((status = 'pass' and data_location is null and schema_location is null and absolute_schema_location is null and error is null)
      or (status != 'pass' and data_location is not null and schema_location is not null and absolute_schema_location is not null and error is not null)),
    check (absolute_schema_location is null or (absolute_schema_location is not null and absolute_schema_location not like 'http%'))
  );

  create index validation_result_json_schema_id_idx on validation_result (json_schema_id);

  create table validation_state_member (
    validation_state_id uuid not null references validation_state (id) on delete cascade,
    validation_result_id uuid not null references validation_result (id) on delete cascade,
    result_order integer not null check (result_order >= 0),
    primary key (validation_state_id, validation_result_id),
    unique (validation_state_id, result_order)
  );

  create index validation_state_member_validation_result_id_idx on validation_state_member (validation_result_id);

  grant select on all tables in schema public to conch_read_only;

$$);
