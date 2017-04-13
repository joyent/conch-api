#!/bin/bash

PSQL="psql -d preflight -U preflight"

$PSQL < conch.sql

psql -U postgres -d preflight -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
psql -U postgres -d preflight -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto";'

$PSQL < datacenter_staging.sql 

DC_ROOM_ID=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_room WHERE az = 'east-1c'");
echo $DC_ROOM_ID

INSERT_SQL="INSERT INTO datacenter_rack (datacenter_room_id, name, rack_size)"

for RACK in E02 E03 ; do
  $PSQL -c "$INSERT_SQL VALUES ( '$DC_ROOM_ID', '$RACK', 42)"
done

$PSQL < hardware.sql
$PSQL < hardware_profiles.sql
