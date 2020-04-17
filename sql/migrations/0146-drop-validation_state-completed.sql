SELECT run_migration(146, $$

    update validation_state set created = greatest(created, completed);

    alter table validation_state drop column completed;

$$);
