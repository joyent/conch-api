BEGIN;

  -- Implements schema described in OPS-RFD 23
  -- https://github.com/joyent/ops-rfd/tree/master/rfd/0023

  -- It is important that the name constraint is UNIQUE, since we identify the
  -- 'global' workspace by the name 'GLOBAL'. If users were able to create
  -- another workspace also named 'GLOBAL', they might be able to escalate
  -- their privileges.
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
    user_id      UUID     NOT NULL REFERENCES user_account(id),
    workspace_id UUID     NOT NULL REFERENCES workspace(id),
    role_id      INTEGER  NOT NULL REFERENCES role(id),
    UNIQUE (user_id, workspace_id)
  );

  CREATE INDEX ON user_workspace_role (user_id);

  CREATE TABLE workspace_datacenter_room (
    workspace_id       UUID REFERENCES workspace(id),
    datacenter_room_id UUID REFERENCES datacenter_room(id),
    UNIQUE (workspace_id, datacenter_room_id)
  );

  CREATE INDEX ON workspace_datacenter_room (workspace_id);

  -- Add all datacenter rooms to the global workspace
  INSERT INTO workspace_datacenter_room (workspace_id, datacenter_room_id)
  SELECT workspace.id, datacenter_room.id
  FROM workspace, datacenter_room
  WHERE workspace.name = 'GLOBAL';

  -- Add email column to user_account
  ALTER TABLE user_account ADD COLUMN email TEXT;
  ALTER TABLE user_account ADD CONSTRAINT user_account_email_key UNIQUE (email);


  -- Trigger to make sure all datacenter rooms are added to the global
  -- workspace. This should be done explicitly in code, but this trigger acts
  -- as a safe-guard
  CREATE OR REPLACE FUNCTION add_room_to_global_workspace()
  RETURNS TRIGGER AS $BODY$
  BEGIN
    INSERT INTO workspace_datacenter_room (workspace_id, datacenter_room_id)
    SELECT workspace.id, NEW.id
    FROM workspace
    WHERE workspace.name = 'GLOBAL'
    ON CONFLICT (workspace_id, datacenter_room_id) DO NOTHING;
    return NEW;
  END;
  $BODY$ LANGUAGE 'plpgsql';

  CREATE TRIGGER all_rooms_in_global_workspace AFTER INSERT
    ON datacenter_room
    FOR EACH ROW EXECUTE PROCEDURE add_room_to_global_workspace();

  -- Create a workspace for each existing user using their current
  -- datacenter_room access so the change will be transparent when they log in
  WITH user_access (user_id, name, datacenter_room_id) as (
    SELECT user_id, u.name, datacenter_room_id
    FROM user_datacenter_room_access
    JOIN user_account u
      ON user_id = u.id
  ), new_workspace (id, name) AS (
    INSERT INTO workspace (parent_workspace_id, name, description)
    SELECT DISTINCT
      (SELECT id from workspace where name = 'GLOBAL'),
      ua.name, 'Transition workspace for user ' || ua.name
    FROM user_access ua
    RETURNING id, name
  ), add_rooms AS (
    INSERT INTO workspace_datacenter_room (workspace_id, datacenter_room_id)
    SELECT nw1.id, ua.datacenter_room_id
    FROM new_workspace nw1
    JOIN user_access ua
      ON nw1.name = ua.name
  )
    INSERT INTO user_workspace_role (user_id, workspace_id, role_id)
    SELECT DISTINCT ua.user_id, nw2.id,
      (SELECT id FROM role where name = 'Integrator')
    FROM new_workspace nw2
    JOIN user_access ua
      ON nw2.name = ua.name;

  DROP TABLE user_datacenter_room_access;

COMMIT;

