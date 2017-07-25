#!/bin/bash

set -x
set -e

# Including this file elsewhere may be useful.

PSQL="psql -d conch -U conch"

TRITON_RACK=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_rack_role WHERE name = 'TRITON'" )
CERES_RACK=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_rack_role WHERE name = 'CERES'" )
MANTA_RACK=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_rack_role WHERE name = 'MANTA'" )
MANTA_TALL_RACK=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_rack_role WHERE name = 'MANTA_TALL'" )

F10_SWITCH=$( $PSQL -q -t -A -c "SELECT id FROM hardware_product WHERE name = 'F10-S4048'" )
SHRIMP=$( $PSQL -q -t -A -c "SELECT id FROM hardware_product WHERE name = 'Joyent-Storage-Platform-7001"  )
HA=$( $PSQL -q -t -A -c "SELECT id FROM hardware_product WHERE name = 'Joyent-Compute-Platform-3301'" )
HB=$( $PSQL -q -t -A -c "SELECT id FROM hardware_product WHERE name = 'Joyent-Storage-Platform-7201'" )
HC=$( $PSQL -q -t -A -c "SELECT id FROM hardware_product WHERE name = 'Joyent-Compute-Platform-3302'" )
