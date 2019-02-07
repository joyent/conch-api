BEGIN;

	alter table workflow_lifecycle drop column version;

	alter table workflow_lifecycle add unique(role_id);

COMMIT;
