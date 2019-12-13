SELECT run_migration(141, $$

    alter table relay add column user_id uuid references user_account (id);

    update relay
        set user_id = user_relay_connection.user_id,
            last_seen = greatest(relay.last_seen, user_relay_connection.last_seen)
        from user_relay_connection
        where user_relay_connection.relay_id = relay.id;

    -- these relays were never used and don't need to be preserved.
    delete from relay where user_id is null;

    create index relay_user_id on relay (user_id);

    alter table relay alter column user_id set not null;
    drop table user_relay_connection;

$$);
