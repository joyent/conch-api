SELECT run_migration(83, $$

    delete from rack where deactivated is not null;
    alter table rack drop column deactivated;

$$);
