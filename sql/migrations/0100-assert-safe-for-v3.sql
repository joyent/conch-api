SELECT run_migration(100, $$

    do $inner$ begin
        assert (select max(id) from migration) = 94, 'not all v2 migrations have been run; cannot proceed with v3 upgrade';
    end; $inner$;

$$);
