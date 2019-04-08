SELECT run_migration(89, $$

    -- first, before touching this huge table, let's get rid of all expired
    -- tokens as they are useless...
    delete from user_session_token where expires < now();

    alter table user_session_token
        add column name text,
        add column created timestamp with time zone default now() not null,
        add column last_used timestamp with time zone;

    -- all existing entries are JWTs; label them accordingly
    with tokens_with_names as (
    select
        token_hash,
        user_id,
        row_number() over (partition by user_id order by expires) as num
        from user_session_token
    )
    update user_session_token
        set name = concat('login_jwt_', num)
        from tokens_with_names
        where
            user_session_token.user_id = tokens_with_names.user_id
            and user_session_token.token_hash = tokens_with_names.token_hash;

    alter table user_session_token alter name set not null;

    create unique index user_session_token_user_id_name_key
        on user_session_token (user_id, name);

$$);
