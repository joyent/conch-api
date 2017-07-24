#!/bin/bash

PSQL="psql -d conch -U conch"

for DC in arcadia-planitia-1a arcadia-planitia-1b arcadia-planitia-1c  \
          hellas-planitia-1a  hellas-planitia-1b  hellas-planitia-1c \
          halimede-1a halimede-1b halimede-1c \
          psamathe-1a psamathe-1b psamathe-1c \
          neso-1a     neso-1b     neso-1c          
do 
  DC_ROOM_ID=$( $PSQL -q -t -A -c "SELECT id FROM datacenter_room WHERE az = '$DC'");
  echo $DC_ROOM_ID

  INSERT_SQL="INSERT INTO datacenter_rack (datacenter_room_id, name, rack_size, role)"

  for RACK in A01 A02 A03 ; do
    $PSQL -c "$INSERT_SQL VALUES ( '$DC_ROOM_ID', '$RACK', 42, 'TRITON' )"
  done

  for RACK in B01 B02 B03 ; do
    $PSQL -c "$INSERT_SQL VALUES ( '$DC_ROOM_ID', '$RACK', 42, 'MANTA' )"
  done
done
