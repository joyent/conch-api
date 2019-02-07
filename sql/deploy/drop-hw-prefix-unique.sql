BEGIN;

    -- Remove the UNIQUE constraint on the hardware_product.prefix field
    ALTER TABLE hardware_product DROP constraint hardware_product_prefix_key;

COMMIT;

