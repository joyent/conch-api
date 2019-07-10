SELECT run_migration(120, $$

    -- all existing tokens are invalid since their payload contains
    -- discontinued fields, and all application secrets are being rotated out.
    delete from user_session_token;

    alter table user_session_token
        add column id uuid default gen_random_uuid() not null,
        drop constraint user_session_token_pkey,
        drop column token_hash,
        add primary key (id);

$$);
