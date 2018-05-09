SELECT run_migration(31, $$
    -- Adds a function to retrieve all of the devices in the workspaces by
    -- virtue of their rack location
    -- IMPORTANT: If the device table ever changes, this function MUST be
    -- updated (`create or replace function...`) with the new fields.
	CREATE OR REPLACE FUNCTION workspace_devices(IN workspace_id uuid)
	RETURNS TABLE(
		id text, system_uuid uuid, hardware_product uuid, state text, health text,
		graduated timestamptz, deactivated timestamptz, last_seen timestamptz,
		created timestamptz, updated timestamptz, uptime_since timestamptz,
		validated timestamptz, latest_triton_reboot timestamptz, triton_uuid uuid,
		asset_tag text, triton_setup timestamptz, role uuid
	) AS
	$BODY$

	BEGIN
		RETURN QUERY EXECUTE'
		SELECT device.*
		FROM device
		JOIN device_location loc
		ON loc.device_id = device.id
		JOIN datacenter_rack rack
		ON rack.id = loc.rack_id
		WHERE device.deactivated IS NULL
		AND (
			rack.datacenter_room_id IN (
				SELECT datacenter_room_id
				FROM workspace_datacenter_room
				WHERE workspace_id = $1
			)
			OR rack.id IN (
				SELECT datacenter_rack_id
				FROM workspace_datacenter_rack
				WHERE workspace_id = $1
			)
		);' USING $1;
	END;
	$BODY$
LANGUAGE plpgsql STABLE;

$$);
