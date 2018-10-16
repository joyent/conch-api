SELECT run_migration(67, $$

    -- when device_report is deleted, delete validation_state records that point to it
    alter table validation_state
        drop constraint validation_state_device_report_id_fkey,
        add constraint validation_state_device_report_id_fkey
            foreign key (device_report_id) references device_report(id) on delete cascade;

    -- when validation_state is deleted, delete validation_state_member records that point to it
    alter table validation_state_member
        drop constraint validation_state_member_validation_state_id_fkey,
        add constraint validation_state_member_validation_state_id_fkey
            foreign key (validation_state_id) references validation_state(id) on delete cascade;

$$);
