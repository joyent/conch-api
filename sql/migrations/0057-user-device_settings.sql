SELECT run_migration(57, $$

    alter table user_settings rename to user_setting;
    alter table user_setting rename constraint user_settings_user_id_fkey to user_setting_user_id_fkey;
    alter index user_settings_pkey rename to user_setting_pkey;
    alter index user_settings_user_id_name_idx rename to user_setting_user_id_name_idx;

    alter table device_settings rename to device_setting;
    alter table device_setting rename constraint device_settings_device_id_fkey to device_setting_device_id_fkey;
    alter index device_settings_pkey rename to device_setting_pkey;
    alter index device_settings_device_id_idx rename to device_setting_device_id_idx;
    alter index device_settings_device_id_name_idx rename to device_setting_device_id_name_idx;

    alter table device_setting alter value drop not null;

$$);
