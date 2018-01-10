SELECT run_migration(19, $$

    -- Add a new usb_num column.
    ALTER TABLE hardware_product_profile ADD COLUMN usb_num integer;

    -- Set all profiles to require 1 usb disk
    UPDATE hardware_product_profile SET usb_num = 1;

    -- Set JCP-3211 to require 0 usb disks
    UPDATE hardware_product_profile SET usb_num = 0 WHERE product_id =
    (SELECT id FROM hardware_product WHERE name='Joyent-Compute-Platform-3211');

    -- Adjust usb_num to NOT NULL after we have placed a value in each row.
    ALTER TABLE hardware_product_profile ALTER COLUMN usb_num SET NOT NULL;

$$);
