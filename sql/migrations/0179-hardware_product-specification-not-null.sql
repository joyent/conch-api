SELECT run_migration(179, $$

  update hardware_product set specification = '{}' where specification is null;

  alter table hardware_product alter column specification set default '{}',
    alter column specification set not null;

$$);
