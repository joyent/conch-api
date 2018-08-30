SELECT run_migration(42, $$

    alter table user_account drop constraint if exists user_account_email_key;
    alter table user_account drop constraint if exists user_account_name_key;
    create unique index user_account_email_key on user_account (email) where deactivated is null;
    create unique index user_account_name_key on user_account (name) where deactivated is null;

$$);
