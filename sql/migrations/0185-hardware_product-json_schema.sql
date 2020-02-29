SELECT run_migration(185, $$

  create table hardware_product_json_schema (
    hardware_product_id uuid not null references hardware_product (id),
    json_schema_id uuid not null references json_schema (id),
    added timestamp with time zone default now() not null,
    added_user_id uuid not null references user_account (id),
    primary key (hardware_product_id, json_schema_id)
  );

  grant select on all tables in schema public to conch_read_only;

$$);
