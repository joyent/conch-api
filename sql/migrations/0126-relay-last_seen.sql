SELECT run_migration(126, $$

    alter table relay add column last_seen timestamp with time zone;

    with relay_updates as
    (
        select
            relay_id,
            last_seen,
            (row_number() over (partition by relay_id order by last_seen desc)) as result_num
        from (
            select relay_id, last_seen
            from
                ((select relay_id, last_seen from device_relay_connection)
                union
                (select relay_id, last_seen from user_relay_connection)
            ) as connections
        ) as rseen
    )
    update relay
        set last_seen = relay_updates.last_seen
        from relay_updates
        where relay.id = relay_updates.relay_id and result_num = 1;

    update relay set last_seen = created where last_seen is null;

    alter table relay
        alter column last_seen set default now(),
        alter column last_seen set not null;

$$);
