SELECT run_migration(37, $$
	create table user_account_bak_v2_15 as table user_account;

	-- to see the duplicates, do:
	-- select u1.* from user_account u1 inner join user_account u2 ON lower(u1.email) = lower(u2.email) and u1.created < u2.created;

	delete from user_account where id in ( select distinct u1.id from user_account u1 inner join user_account u2 ON lower(u1.email) = lower(u2.email) and u1.created < u2.created );
$$);

