SELECT run_migration(47, $$

    drop table device_validate;
    drop table device_validate_criteria;

$$);
