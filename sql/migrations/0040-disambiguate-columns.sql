SELECT run_migration(40, $$

    alter table device rename column hardware_product to hardware_product_id;
    alter table device rename column role to device_role_id;
    alter table datacenter_rack rename column role to datacenter_rack_role_id;

    drop function workspace_devices(uuid);

	CREATE OR REPLACE FUNCTION workspace_devices(IN workspace_id uuid)
	RETURNS TABLE(
		id text, system_uuid uuid, hardware_product_id uuid, state text, health text,
		graduated timestamptz, deactivated timestamptz, last_seen timestamptz,
		created timestamptz, updated timestamptz, uptime_since timestamptz,
		validated timestamptz, latest_triton_reboot timestamptz, triton_uuid uuid,
		asset_tag text, triton_setup timestamptz, device_role_id uuid
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
