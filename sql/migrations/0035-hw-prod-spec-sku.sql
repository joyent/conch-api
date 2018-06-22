-- name: manta-storage-v3-512g-36-8tb (Conch specific)
-- sku: 600-0025-001
-- generation_name: Joyent-S10G4
-- legacy_product_name: The old-style Product Name (JSP/JCP-XXXX), still needed
-- for mapping purposes with the Dells.

SELECT run_migration(35, $$
	alter table hardware_product add column specification jsonb;

	alter table hardware_product drop constraint hardware_product_alias_key;

	alter table hardware_product add column sku text;
	alter table hardware_product add unique(sku);

	alter table hardware_product add column generation_name text;

	alter table hardware_product add column legacy_product_name text;

	update hardware_product set legacy_product_name = name;

	-- Shrimp Mk III
	update hardware_product set name = 'smci-storage-v3-512g-36-sata-8tb' where name = 'Joyent-Storage-Platform-7001';
	update hardware_product set sku = '600-0025-001' where name = 'smci-storage-v3-512g-36-sata-8tb';
	update hardware_product set generation_name = 'Joyent-S10G4' where name = 'smci-storage-v3-512g-36-sata-8tb';

	-- Shrimp Mk III.5
	update hardware_product set name = 'smci-storage-v3-256g-36-sata-12tb' where name = 'Joyent-Storage-Platform-4201';
	update hardware_product set sku = 'Joyent-Storage-Platform-4201' where name = 'smci-storage-v3-256g-36-sata-12tb';
	update hardware_product set generation_name = 'Joyent-S10G5' where name = 'smci-storage-v3-256g-36-sata-12tb';

	-- CERES
	-- We don't currently provide a SKU or generation for CERES systems.
	update hardware_product set name = 'dell-2u-compute-v1-256g-10-12tb' where name = 'Joyent-Compute-Platform-3211';

	-- HAr2
	update hardware_product set name = 'smci-2u-compute-512g-16-sata-1tb' where name = 'Joyent-Compute-Platform-3101';
	update hardware_product set sku = '600-0027-001' where name = 'smci-2u-compute-512g-16-sata-1tb';
	update hardware_product set generation_name = 'Joyent-M12G4' where name = 'smci-2u-compute-512g-16-sata-1tb';

	-- HA
	update hardware_product set name = 'dell-2u-compute-512g-16-sata-1tb' where name = 'Joyent-Compute-Platform-3301';
	update hardware_product set sku = '600-0023-001' where name = 'dell-2u-compute-512g-16-sata-1tb';
	update hardware_product set generation_name = 'Joyent-M11G4' where name = 'dell-2u-compute-512g-16-sata-1tb';

	-- HC
	update hardware_product set name = 'dell-2u-compute-256g-16-ssd-1tb' where name = 'Joyent-Compute-Platform-3302';
	update hardware_product set sku = '600-0024-001' where name = 'dell-2u-compute-256g-16-ssd-1tb';
	update hardware_product set generation_name = 'Joyent-M11G4' where name = 'dell-2u-compute-256g-16-ssd-1tb';

	-- HB
	update hardware_product set name = 'smci-4u-storage-256g-36-sata-8tb' where name = 'Joyent-Storage-Platform-7201';
	update hardware_product set sku = '600-0028-001' where name = 'smci-4u-storage-256g-36-sata-8tb';
	update hardware_product set generation_name = 'Joyent-S10G4' where name = 'smci-4u-storage-256g-36-sata-8tb';

	-- JA
	update hardware_product set name = 'smci-2u-compute-512g-16-sas-1tb' where name = 'Joyent-Compute-Platform-4101';
	update hardware_product set sku = '600-0032-001' where name = 'smci-2u-compute-512g-16-sas-1tb';
	update hardware_product set generation_name = 'Joyent-M12G5' where name = 'smci-2u-compute-512g-16-sas-1tb';

	-- JB
	update hardware_product set name = 'smci-2u-storage-256g-12-sas-12tb' where name = 'Joyent-Compute-Platform-4201';
	update hardware_product set sku = '600-0033-001' where name = 'smci-2u-storage-256g-12-sas-12tb';
	update hardware_product set generation_name = 'Joyent-S12G5' where name = 'smci-2u-storage-256g-12-sas-12tb';

	-- JC (12)
	update hardware_product set name = 'smci-2u-compute-512g-12-ssd-2tb' where name = 'Joyent-Compute-Platform-4102';
	update hardware_product set sku = '600-0034-001' where name = 'smci-2u-compute-512g-12-ssd-2tb';
	update hardware_product set generation_name = 'Joyent-M12G5' where name = 'smci-2u-compute-512g-12-ssd-2tb';
$$);
