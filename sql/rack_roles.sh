#!/bin/bash

set -x
set -e

PSQL="psql -d conch -U conch"

ROLE_INSERT_SQL="INSERT INTO datacenter_rack_role ( name, rack_size )"

for ROLE in TRITON MANTA CERES ; do
  $PSQL -c "$ROLE_INSERT_SQL VALUES ( '$ROLE', 45 )"
done

$PSQL -c "$ROLE_INSERT_SQL VALUES ( 'MANTA_TALL', 62 )"
