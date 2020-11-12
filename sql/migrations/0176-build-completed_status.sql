SELECT run_migration(176, $$

  create type completed_status_enum as enum ('failure', 'success');
  alter table build add column completed_status completed_status_enum;

  update build set completed_status = 'success' where completed is not null;

  alter table build
    add constraint build_completed_xnor_completed_status_check check
      ((completed is null and completed_status is null) or (completed is not null and completed_status is not null));

$$);
