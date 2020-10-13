SELECT run_migration(172, $$

    alter table build add column links text[] not null default '{}';
    create index build_links_idx on build using gin (links);

    alter table rack add column links text[] not null default '{}';
    create index rack_links_idx on rack using gin (links);

$$);
