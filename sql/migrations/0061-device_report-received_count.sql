SELECT run_migration(61, $$

    alter table device_report
        add column last_received timestamp with time zone,
        add column received_count integer default 1 not null;

    update device_report set last_received = created;

    alter table device_report alter last_received set default now(),
                              alter last_received set not null;

$$);
