INSERT INTO hardware_vendor (name) VALUES ('DellBell');
INSERT INTO hardware_vendor (name) VALUES ('SuperDuperMicro');

INSERT INTO hardware_product (name, alias, prefix, vendor, legacy_product_name)
       VALUES ( 'Switch', 'Farce 10', 'F10', ( SELECT id FROM hardware_vendor WHERE name = 'DellBell' ), 'FuerzaDiaz' );

INSERT INTO hardware_product (name, alias, prefix, vendor, sku, generation_name, legacy_product_name)
       VALUES ( '2-ssds-1-cpu', 'Test Compute', 'HA', ( SELECT id FROM hardware_vendor WHERE name = 'DellBell' ), '550-551-001', 'Joyent-G1', 'Joyent-Compute-Platform' );

INSERT INTO hardware_product (name, alias, prefix, vendor, sku, generation_name, legacy_product_name)
       VALUES ( '65-ssds-2-cpu', 'Test Storage', 'MS', ( SELECT id FROM hardware_vendor WHERE name = 'SuperDuperMicro' ), '550-552-003', 'Joyent-S1', 'Joyent-Storage-Platform' );
