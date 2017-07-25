#!/bin/bash

set -e
set -o

source ./rack_include.sh

PSQL="psql -d conch -U conch"

for DC in arcadia-planitia-1a arcadia-planitia-1b arcadia-planitia-1c  \
          hellas-planitia-1a  hellas-planitia-1b  hellas-planitia-1c \
          halimede-1a halimede-1b halimede-1c \
          psamathe-1a psamathe-1b psamathe-1c \
          neso-1a     neso-1b     neso-1c          
do 
  DC_ROOM_ID=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_room WHERE az = '$DC'");

  RACK_INSERT_SQL="INSERT INTO datacenter_rack (datacenter_room_id, name, role)"

  for RACK in A01 A02 A03 ; do
    $PSQL -c "$RACK_INSERT_SQL VALUES ( '$DC_ROOM_ID', '$RACK', '$TRITON_RACK' )"
  done

  A01=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_rack WHERE datacenter_room_id = '$DC_ROOM_ID' AND name = 'A01'" )
  A02=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_rack WHERE datacenter_room_id = '$DC_ROOM_ID' AND name = 'A02'" )
  A03=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_rack WHERE datacenter_room_id = '$DC_ROOM_ID' AND name = 'A03'" )

  LAYOUT_INSERT_SQL="INSERT INTO datacenter_rack_layout (rack_id, product_id, ru_start)" 

  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 1 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 3 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 5 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 7 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 9 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 11 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 13 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 15 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 17 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 19 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 21 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 23 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 25 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 27 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 29 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 31 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 33 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 35 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$HA', 37 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$F10_SWITCH', 43 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A01', '$F10_SWITCH', 44 )"

  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 1 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 3 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 5 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 7 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 9 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 11 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 13 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 15 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 17 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 19 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 21 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 23 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 25 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 27 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 29 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 31 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 33 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 35 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$HC', 37 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$F10_SWITCH', 43 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A02', '$F10_SWITCH', 44 )"

  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A03', '$HB', 1 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A03', '$HB', 5 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A03', '$HB', 9 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A03', '$F10_SWITCH', 43 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$A03', '$F10_SWITCH', 44 )"
  
  for RACK in B01 B02 B03 ; do
    $PSQL -c "$RACK_INSERT_SQL VALUES ( '$DC_ROOM_ID', '$RACK', '$MANTA_RACK' )"
  done

  B01=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_rack WHERE datacenter_room_id = '$DC_ROOM_ID' AND name = 'B01'" )
  B02=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_rack WHERE datacenter_room_id = '$DC_ROOM_ID' AND name = 'B02'" )
  B03=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_rack WHERE datacenter_room_id = '$DC_ROOM_ID' AND name = 'B03'" )
  
  # Standard Manta rack
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$SHRIMP', 1 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$SHRIMP', 5 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$SHRIMP', 9 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$SHRIMP', 13 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$SHRIMP', 17 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$SHRIMP', 21 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$SHRIMP', 25 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$SHRIMP', 29 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$SHRIMP', 33 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$HA', 37 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$HA', 39 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$F10_SWITCH', 43 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B01', '$F10_SWITCH', 44 )"

  # Standard Manta rack
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$SHRIMP', 1 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$SHRIMP', 5 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$SHRIMP', 9 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$SHRIMP', 13 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$SHRIMP', 17 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$SHRIMP', 21 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$SHRIMP', 25 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$SHRIMP', 29 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$SHRIMP', 33 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$HA', 37 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$HA', 39 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$F10_SWITCH', 43 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B02', '$F10_SWITCH', 44 )"

  # Non-standard metadata heavy Manta rack
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$SHRIMP', 1 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$SHRIMP', 5 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$HA', 19 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$HA', 21 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$HA', 23 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$HA', 25 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$HA', 27 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$HA', 29 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$HA', 31 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$HA', 33 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$HA', 35 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$HA', 37 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$HA', 39 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$F10_SWITCH', 43 )"
  $PSQL -c "$LAYOUT_INSERT_SQL VALUES ( '$B03', '$F10_SWITCH', 44 )"

done
