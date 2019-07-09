SELECT run_migration(111, $$

    alter table device drop column state;

$$);
