SELECT run_migration(150, $$

    alter table validation_state_member
        add constraint validation_state_member_validation_state_id_result_order_key unique (validation_state_id, result_order);

$$);
