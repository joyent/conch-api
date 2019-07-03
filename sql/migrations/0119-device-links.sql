SELECT run_migration(119, $$

    alter table device add column links text[] not null default '{}';

    create index device_links_idx on device using gin (links);

    create function array_cat_distinct(anyarray, anyarray) returns anyarray as $f$
      select array(select distinct unnest(array_cat($1, $2)) order by 1);
    $f$ language sql immutable;

$$);
