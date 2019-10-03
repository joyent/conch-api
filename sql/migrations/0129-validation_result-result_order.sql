SELECT run_migration(129, $$

    -- these are the two validation modules that can produce duplicate
    -- results, with the exception of the result_order.  For cpu_temperature
    -- at least, we can infer the component value; for switch_peers we cannot
    -- as there are multiple sections of result generation, which can fire in
    -- an unpredictable order due to hash ordering of the 'interface' section
    -- of the device report.
    update validation_result
        set component='cpu'||result_order
        from validation
        where validation_result.validation_id = validation.id
            and validation.name = 'cpu_temperature'
            and validation_result.component is null;

    update validation_result
        set component='unknown'||result_order
        from validation
        where validation_result.validation_id = validation.id
            and validation.name = 'switch_peers'
            and validation_result.component is null;


    alter table validation_state_member
        add column result_order integer default 0 not null check (result_order >= 0);

    update validation_state_member
        set result_order = validation_result.result_order
        from validation_result
        where validation_state_member.validation_result_id = validation_result.id;

    alter table validation_state_member alter column result_order drop default;
    alter table validation_result drop column result_order;

    drop index if exists validation_result_all_columns_idx;
    create index validation_result_all_columns_idx on validation_result
        (device_id, hardware_product_id, validation_id, message, hint, status, category, component);

$$);
