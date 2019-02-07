BEGIN;

    drop index user_account_name_key;
    create index user_account_name_key on user_account (name);

COMMIT;
