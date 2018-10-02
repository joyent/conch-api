SELECT run_migration(60, $$

    alter table validation_state add column device_report_id uuid;

    create index validation_state_device_report_id_idx on validation_state (device_report_id);

    alter table validation_state
        add constraint validation_state_device_report_id_fkey foreign key (device_report_id)
            references device_report(id);

    create index validation_state_created_idx on validation_state (created);
    create index validation_state_completed_idx on validation_state (completed);

    create index device_report_created_idx on device_report (created);

$$);
