SELECT run_migration(144, $$

    -- We know that new validation results re-use old validation_result rows whenever possible
    -- (see the end of Conch::ValidationSystem::run_validation_plan), and since release v3.0.0
    -- (where either: 1. merge_validation_results was run a final time, or 2. validation_result
    -- was truncated) there are no duplicates, so it is now safe to turn this index into a
    -- unique constraint.

    alter table validation_result
        add constraint validation_result_all_columns_key unique
        (device_id, hardware_product_id, validation_id, message, hint, status, category, component);

    drop index if exists validation_result_all_columns_idx;
    drop index validation_result_device_id_idx; -- redundant with unique constraint

$$);
