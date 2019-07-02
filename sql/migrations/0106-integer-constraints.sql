SELECT run_migration(106, $$

    alter table migration
        add constraint migration_id_check check (id >= 0);

    alter table device_location
        add constraint device_location_rack_unit_start_check check (rack_unit_start > 0);

    alter table rack_layout
        add constraint rack_layout_rack_unit_start_check check (rack_unit_start > 0);

    alter table rack_role
         add constraint rack_role_rack_size_check check (rack_size > 0);

    alter table relay
         add constraint relay_ssh_port_check check (ssh_port >= 0);

    alter table validation
        add constraint validation_version_check check (version > 0);

    alter table validation_result
        add constraint validation_result_result_order_check check (result_order >= 0);

$$);
