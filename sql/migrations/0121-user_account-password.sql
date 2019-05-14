SELECT run_migration(121, $$

    -- remove all the legacy leading '{CRYPT}' from password_hash.
    update user_account
        set password_hash = substr(password_hash, 8)
        where password_hash like '{CRYPT}%';

    alter table user_account rename column password_hash to password;

$$);
