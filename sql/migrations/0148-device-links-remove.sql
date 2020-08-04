SELECT run_migration(148, $$

    create function array_subtract(anyarray, anyarray) returns anyarray as $f$
      select array(select unnest($1) except select unnest($2) order by 1);
    $f$ language sql immutable;

$$);
