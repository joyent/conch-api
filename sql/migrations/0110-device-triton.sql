SELECT run_migration(110, $$

    insert into device_setting (name, device_id, value)
        select 'latest_triton_reboot', id, latest_triton_reboot::text
        from device where latest_triton_reboot is not null;

    insert into device_setting (name, device_id, value)
        select 'triton_uuid', id, triton_uuid::text
        from device where triton_uuid is not null;

    insert into device_setting (name, device_id, value)
        select 'triton_setup', id, triton_setup::text
        from device where triton_setup is not null;

    alter table device
        drop column latest_triton_reboot,
        drop column triton_uuid,
        drop column triton_setup;

$$);
