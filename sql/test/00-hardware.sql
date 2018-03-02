INSERT INTO hardware_vendor (name) VALUES ('DellHell');
INSERT INTO hardware_vendor (name) VALUES ('SuperDuperMicro');

INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Switch', 'Farce 10', 'F10', ( SELECT id FROM hardware_vendor WHERE name = 'DellHell' ) );

INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Compute-Platform', 'Test Compute', 'HA', ( SELECT id FROM hardware_vendor WHERE name = 'DellHell' ) );

INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Storage-Platform', 'Test Storage', 'MS', ( SELECT id FROM hardware_vendor WHERE name = 'SuperDuperMicro' ) );
