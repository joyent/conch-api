SELECT run_migration(132, $$

    update hardware_product
        set sku = 'placeholder-missing-sku-' || legacy_product_name
        where sku is null or sku = '';

    alter table hardware_product alter column sku set not null;

$$);
