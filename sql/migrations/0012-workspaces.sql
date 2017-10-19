SELECT run_migration(12, $$

  -- Implements schema described in OPS-RFD 23
  -- https://github.com/joyent/ops-rfd/tree/master/rfd/0023
  CREATE TABLE workspace (
    id                  UUID  PRIMARY KEY DEFAULT uuid_generate_v4(),
    name                TEXT  UNIQUE NOT NULL,
    description         TEXT,
    parent_workspace_id UUID  REFERENCES workspace(id)
  );

  INSERT INTO workspace(name, description) VALUES
    ('GLOBAL', 'Global workspace. Ancestor of all workspaces.');

  CREATE TABLE role (
    id          SERIAL PRIMARY KEY,
    name        TEXT   UNIQUE NOT NULL,
    description TEXT
  );

  INSERT INTO role (name, description) VALUES
    ('Administrator', 'Full-access administrator for the workspace'),
    ('Read-only', 'Read-only access for the workspace'),
    ('Integrator', 
      'Integrator has permissions to use Relays and assign Devices to Racks for '
      'the workspace'
    ),
    ('DC Operations', 'DC Operations'),
    ('Integrator Manager',
      'Integrator manager has all the same permissions as the Integrator role, '
      'but may also invite new users to a workspace, create sub-workspaces, and '
      'modify validation parameters.'
    );

  CREATE TABLE user_workspace_role (
    user_id      UUID     REFERENCES user_account(id),
    workspace_id UUID     REFERENCES workspace(id),
    role_id      INTEGER  REFERENCES role(id),
    UNIQUE (user_id, workspace_id, role_id)
  );

  CREATE INDEX ON user_workspace_role (user_id);

  CREATE TABLE workspace_datacenter_room (
    workspace_id       UUID REFERENCES workspace(id),
    datacenter_room_id UUID REFERENCES datacenter_room(id),
    UNIQUE (workspace_id, datacenter_room_id)
  );

  CREATE INDEX ON workspace_datacenter_room (workspace_id);

$$);


