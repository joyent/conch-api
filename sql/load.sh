#!/bin/bash

set -e

psql -U postgres -d conch -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
psql -U postgres -d conch -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto";'

PSQL="psql -A -U conch -d conch"

for F in conch.sql hardware.sql zpool_profiles.sql hardware_profiles.sql validate_criteria.sql ; do
  echo $F
  $PSQL < $F
done

