BEGIN;

	create table user_session_token (
		user_id    uuid        not null references user_account(id),
		token_hash bytea       not null,
		expires    timestamptz not null,
		primary key (user_id, token_hash)
	);

	-- fast deleting of expired tokens
	create index on user_session_token (expires asc);

COMMIT;

