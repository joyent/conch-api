-- add 'deactivated' column to user_account
SELECT run_migration(36, $$
	alter table user_account add column deactivated timestamptz DEFAULT NULL;
$$);
