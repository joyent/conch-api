#/bin/bash

DC_ID=$( psql -A -d conch -c 'SELECT id FROM datacenter_room WHERE az = "eu-ams-1a"');

INSERT_SQL="INSERT INTO datacenter_rack (datacenter_id, name, rack_size)"

for RACK in 0303 0304 0305 0306 0307 0308 0309 0310 0311 0312 0313 0316 0408 0412 \
            0415 0209 0210 0211 0213 0403 0404 0214 0215 0405 0406 0407 0413 0414 \
            0314 0315 0113 0114 0216 0109 0110 0111 0112 0115 0116 ; do
  psql -d conch -c "$INSERT_SQL VALUES ('$DC_ID', '$RACK', 45)"
done
