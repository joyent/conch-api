SELECT run_migration(173, $$

    -- set all "legacy" builds to completed, using the latest device report timestamp
    -- as the completed value.

    with mycompleted as (
        select
            build.id as build_id,
            greatest(
                (select max(dr1.created)
                    from device device1
                    left join device_report dr1 on dr1.device_id = device1.id
                    where device1.build_id = build.id),
                (select max(dr2.created)
                    from rack
                    left join device_location on device_location.rack_id = rack.id
                    left join device device2 on device2.id = device_location.device_id
                    left join device_report dr2 on dr2.device_id = device2.id
                    where rack.build_id = build.id)
            ) as new_completed
            from build
            where started is not null and completed is null
                and created < '2020-09-17'
        )
    update build
    set completed = mycompleted.new_completed,
    completed_user_id = case when mycompleted.new_completed is null then null
        else (select id from user_account where email = 'ether@joyent.com') end
    from mycompleted
    where mycompleted.build_id = build.id
        and started is not null and completed is null
        and created < '2020-09-17';

$$);
