SELECT run_migration(30, $$

	create table user_session_token (
		user_id    uuid        not null references user_account(id),
		token_hash bytea       not null,
		expires    timestamptz not null,
		primary key (user_id, token_hash)
	);

	-- fast deleting of expired otkens
	create index on user_session_token (expires asc);

	create function delete_expired_tokens() returns void
		as 'delete from user_session_token where expires <= now()'
	language sql;

$$);

