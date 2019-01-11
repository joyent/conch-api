SELECT run_migration(70, $$

    alter table device_spec drop column hardware_product_id;

$$);
