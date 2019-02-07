BEGIN;

    alter table hardware_product drop constraint hardware_product_alias_key;
    create unique index hardware_product_alias_key
        on hardware_product (alias) where deactivated is null;

    alter table hardware_product drop constraint hardware_product_name_key;
    create unique index hardware_product_name_key
        on hardware_product (name) where deactivated is null;

    alter table hardware_product drop constraint hardware_product_sku_key;
    create unique index hardware_product_sku_key
        on hardware_product (sku) where deactivated is null;

COMMIT;
