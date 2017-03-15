#!/bin/bash

for AZ in eu-ams-1a eu-ams-1b eu-ams-1c ; do
  DC_ID=$( psql -A -d conch -c 'SELECT id FROM datacenter_room WHERE az = "$AZ"');

  for RACK in 0305 0306 0307 0308 0309 0310 0311 0312 0313 0316 0408 0412 0415 ; do
    RACK_ID=$( psql -A -d conch -c 'SELECT id FROM ')

  done
done
