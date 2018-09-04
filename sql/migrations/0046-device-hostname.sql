SELECT run_migration(46, $$

    alter table device add column hostname text;

$$);
