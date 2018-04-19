SELECT run_migration(27, $$

	drop index workflow_name_idx;
	alter table workflow drop constraint workflow_name_version_key;
	alter table workflow add unique (name);

	alter table workflow drop column version;
	alter table workflow drop column deactivated;

	drop index workflow_lifecycle_name_version_idx;
	alter table workflow_lifecycle add unique(name);
	alter table workflow_lifecycle drop column deactivated;

$$);
