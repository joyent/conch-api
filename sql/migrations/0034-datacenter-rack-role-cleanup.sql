SELECT run_migration(34, $$
	alter table datacenter_rack_role add column created timestamptz not null default current_timestamp; 
	alter table datacenter_rack_role add column updated timestamptz not null default current_timestamp; 

	alter table datacenter_rack_role add unique(name);
$$);

