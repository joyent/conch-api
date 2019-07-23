SELECT run_migration(122, $$

    alter table user_account add column last_seen timestamp with time zone;

$$);
