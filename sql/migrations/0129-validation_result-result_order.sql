SELECT run_migration(129, $$

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
