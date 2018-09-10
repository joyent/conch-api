SELECT run_migration(50, $$

    alter table device drop column device_role_id;
    drop table if exists device_role_service, device_role, device_service restrict;

$$);
