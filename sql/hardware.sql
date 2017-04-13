INSERT INTO hardware_vendor (name) VALUES ( 'Dell');
INSERT INTO hardware_vendor (name) VALUES ( 'SuperMicro');

INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Dell-R730-9001', 'Priestriver A', 'PA', ( SELECT id FROM hardware_vendor WHERE name = 'Dell' ) );
INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Dell-R730-9002', 'Priestriver C', 'PC', ( SELECT id FROM hardware_vendor WHERE name = 'Dell' ) );
INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Compute-Platform-3301', 'Hallasan A', 'HA', ( SELECT id FROM hardware_vendor WHERE name = 'Dell' ) );
INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Compute-Platform-3302', 'Hallasan C', 'HC', ( SELECT id FROM hardware_vendor WHERE name = 'Dell' ) );
INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'CERES', 'Type 1', 'CE', ( SELECT id FROM hardware_vendor WHERE name = 'Dell' ) );

INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Compute-Platform-1101', 'Richmond A', 'RA', ( SELECT id FROM hardware_vendor WHERE name = 'SuperMicro' ) );
INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Compute-Platform-1201', 'Richmond B', 'RB', ( SELECT id FROM hardware_vendor WHERE name = 'SuperMicro' ) );
INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Compute-Platform-1102', 'Richmond C', 'RC', ( SELECT id FROM hardware_vendor WHERE name = 'SuperMicro' ) );
INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Compute-Platform-2102', 'Tenderloin C', 'TC', ( SELECT id FROM hardware_vendor WHERE name = 'SuperMicro' ) );
INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Storage-Platform-5001', 'Mantis Shrimp MkII', 'MS, RM', ( SELECT id FROM hardware_vendor WHERE name = 'SuperMicro' ) );
INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Storage-Platform-7201', 'Hallasan B', 'HB', ( SELECT id FROM hardware_vendor WHERE name = 'SuperMicro' ) );
INSERT INTO hardware_product (name, alias, prefix, vendor)
       VALUES ( 'Joyent-Storage-Platform-7001', 'Mantis Shrimp MkIII', 'MS', ( SELECT id FROM hardware_vendor WHERE name = 'SuperMicro' ) );
