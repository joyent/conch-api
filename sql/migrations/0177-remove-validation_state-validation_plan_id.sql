SELECT run_migration(177, $$

  -- this is redundant information that serves no real purpose.
  -- individual validation results (and their validation_ids) are already
  -- associated with a validation_state.
  alter table validation_state drop column validation_plan_id;

$$);
