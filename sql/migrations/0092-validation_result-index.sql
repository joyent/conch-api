SELECT run_migration(92, $$

    -- this is used when inserting validation_state + validation_state_member +
    -- validation_result records at the end of running a validation_plan and we seek
    -- to re-use old records where possible instead of creating a new ones
    create index validation_result_all_columns_idx on validation_result
        (device_id, hardware_product_id, validation_id, message, hint, status, category, component_id, result_order);

$$);
