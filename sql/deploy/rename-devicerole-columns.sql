BEGIN;

    alter table device_role_services rename to device_role_service;
    alter table device_role_service rename column role_id to device_role_id;
    alter table device_role_service rename column service_id to device_role_service_id;

    alter table device_specs rename to device_spec;
    alter table hardware_profile_settings rename to hardware_profile_setting;

    alter table hardware_product rename column vendor to hardware_vendor_id;
    alter table hardware_profile_setting rename column profile_id to hardware_product_profile_id;
    alter table hardware_product_profile rename column product_id to hardware_product_id;
    alter table datacenter_rack_layout rename column product_id to hardware_product_id;
    alter table device_spec rename column product_id to hardware_product_id;
    alter table device_validate_criteria rename column product_id to hardware_product_id;

    alter table datacenter_room rename column datacenter to datacenter_id;

COMMIT;
