-- add 'deactivated' column to user_account
BEGIN;
	alter table user_account add column deactivated timestamptz DEFAULT NULL;
COMMIT;
