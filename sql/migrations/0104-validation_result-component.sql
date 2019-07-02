SELECT run_migration(104, $$

    alter table validation_result rename column component_id to component;

$$);
