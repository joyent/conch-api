SELECT run_migration(136, $$

    drop index user_account_email_key;
    create unique index user_account_email_key
        on user_account (lower(email)) where deactivated is null;

$$);
