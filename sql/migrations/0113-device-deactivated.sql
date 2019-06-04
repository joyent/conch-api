SELECT run_migration(113, $$

    update device set phase = 'decommissioned' where deactivated is not null;

    alter table device drop column deactivated;

$$);
