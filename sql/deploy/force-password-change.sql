BEGIN;
	alter table user_account add column refuse_session_auth boolean default false not null;
	alter table user_account add column force_password_change boolean default false not null;
COMMIT;
