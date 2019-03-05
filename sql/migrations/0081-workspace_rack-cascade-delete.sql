SELECT run_migration(81, $$

    -- when rack is deleted, delete workspace_rack records that point to it
    -- (this should have always existed, but somehow got overlooked)
    alter table workspace_rack
        drop constraint workspace_rack_rack_id_fkey,
        add constraint workspace_rack_rack_id_fkey
            foreign key (rack_id) references rack(id) on delete cascade;

$$);
