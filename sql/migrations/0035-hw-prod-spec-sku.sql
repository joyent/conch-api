# name: manta-storage-v3-512g-36-8tb (Conch specific)
# sku: 600-0025-001
# product_name: Joyent-S10G4

SELECT run_migration(35, $$
	alter table hardware_product add column specification jsonb;
	alter table hardware_product drop constraint hardware_product_alias_key;
	alter table hardware_product add column sku text;
	alter table hardware_product add column product_name text;
	alter hardware_product add unique(sku);

	update hardware_product set product_name = name;
$$);
