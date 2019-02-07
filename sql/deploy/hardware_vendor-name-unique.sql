BEGIN;

    alter table hardware_vendor drop constraint if exists hardware_vendor_name_key;
    create unique index hardware_vendor_name_key
        on hardware_vendor (name) where deactivated is null;

COMMIT;
