SELECT run_migration(14, $$

    -- Workspaces can contain individual racks in addition to whole datacenter rooms
    CREATE TABLE workspace_datacenter_rack (
        workspace_id       UUID REFERENCES workspace(id),
        datacenter_rack_id UUID REFERENCES datacenter_rack(id),
        UNIQUE (workspace_id, datacenter_rack_id)
    );

$$);
