SELECT run_migration(175, $$

    -- this index was created in migration 109,
    -- then removed in migration 135 because it was redundant with
    -- validation_state_device_id_validation_plan_id_completed_idx,
    -- but then that index was removed in migration 146 and so we also lost the first-column index
    -- on device_id as a side effect.
    create index validation_state_device_id_idx on validation_state (device_id);

    -- a quick audit of all tables shows no other inadvertent losses of indexes.

$$);
