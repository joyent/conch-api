SELECT run_migration(145, $$

    alter table user_session_token add column last_ipaddr inet;

$$);
