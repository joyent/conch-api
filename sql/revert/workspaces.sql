-- Revert conch:workspaces from pg

BEGIN;

DROP TRIGGER IF EXISTS all_rooms_in_global_workspace ON datacenter_room;
DROP FUNCTION IF EXISTS add_room_to_global_workspace();
DROP TABLE IF EXISTS workspace CASCADE;

DROP TABLE IF EXISTS workspace_datacenter_room;

DROP TABLE IF EXISTS user_workspace_role;
DROP TABLE IF EXISTS role;

COMMIT;
