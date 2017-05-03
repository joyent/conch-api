#!/bin/bash

PSQL="psql -d preflight -U preflight"

psql -U postgres -d preflight -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
psql -U postgres -d preflight -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto";'

$PSQL < conch.sql

$PSQL < datacenter_ap_se.sql

./datacenter_ap_se_racks.pl

$PSQL < hardware.sql
$PSQL < hardware_profiles.sql
$PSQL < validate_criteria.sql
