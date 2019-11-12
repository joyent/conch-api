SELECT run_migration(137, $$

    drop index user_account_name_key;
    create unique index user_account_name_key on user_account (name) where deactivated is null;

$$);
