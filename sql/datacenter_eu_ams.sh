#!/bin/bash

PSQL="psql -d preflight -U preflight"

psql -U postgres -d preflight -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
psql -U postgres -d preflight -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto";'

$PSQL < conch.sql

$PSQL < datacenter_eu_ams.sql

./datacenter_eu_ams_racks.sh

$PSQL < hardware.sql
$PSQL < hardware_profiles.sql
$PSQL < validate_criteria.sql
