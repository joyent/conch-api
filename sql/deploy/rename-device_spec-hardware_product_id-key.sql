BEGIN;

    alter table device_spec drop column hardware_product_id;

COMMIT;
