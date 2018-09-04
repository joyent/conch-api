SELECT run_migration(45, $$

    alter table datacenter_rack
        add column serial_number text,
        add column asset_tag text;

$$);
