SELECT run_migration(186, $$

  alter table hardware_product alter column cpu_type drop not null;
  update hardware_product set cpu_type = null where cpu_type = '' or cpu_type = 'unknown';

$$);
