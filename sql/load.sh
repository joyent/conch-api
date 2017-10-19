#!/bin/bash

set -e
set -x

BASEDIR=$(cd `dirname $0` && pwd)

psql -U postgres -d conch -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
psql -U postgres -d conch -c 'CREATE EXTENSION IF NOT EXISTS "pgcrypto";'

PSQL="psql -A -U conch -d conch"

for F in conch.sql hardware.sql zpool_profiles.sql hardware_profiles.sql validate_criteria.sql ; do
  $PSQL < $BASEDIR/$F
done

$BASEDIR/rack_roles.sh

# Run migrations
$BASEDIR/run_migrations.sh
