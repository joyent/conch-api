BEGIN;

    create index datacenter_rack_layout_hardware_product_id_idx on datacenter_rack_layout (hardware_product_id);

    create index device_relay_connection_device_id_idx on device_relay_connection (device_id);
    create index device_relay_connection_relay_id_idx on device_relay_connection (relay_id);

    create index user_relay_connection_user_id_idx on user_relay_connection (user_id);
    create index user_relay_connection_relay_id_idx on user_relay_connection (relay_id);

    create index user_session_token_user_id_idx on user_session_token (user_id);

    create index user_setting_user_id_idx on user_setting (user_id);

    create index validation_result_device_id_idx on validation_result (device_id);
    create index validation_result_hardware_product_id_idx on validation_result (hardware_product_id);
    create index validation_result_validation_id_idx on validation_result (validation_id);

    create index validation_state_member_validation_result_id_idx on validation_state_member (validation_result_id);

COMMIT;
