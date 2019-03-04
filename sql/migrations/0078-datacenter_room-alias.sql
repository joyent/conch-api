SELECT run_migration(78, $$

    alter table datacenter_room alter alias set not null;

$$);
