do $$ begin
assert (select max(id) from migration) = 91, 'not all v2 migrations have been run; cannot proceed with v3 upgrade';
end; $$;

SELECT run_migration(100, '');
