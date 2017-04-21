#!/bin/bash

# Shoot me.
SUBNET=$( ifconfig net0 | grep inet | awk '{print $2}' | awk -F. '{print $1,$2}' | sed -e 's/ /\./' )

# Triton UUID can byte-shift the system UUID, so we need both to link them.

# If setup is true, then ensure we're graduated and storing the Triton UUID.
for HOST in $( curl -s $SUBNET.0.44/servers | json -a uuid setup | grep true | awk '{print $1}' ); do
  SN=$( curl -s $SUBNET.0.44/servers/$HOST | json -a sysinfo.'Serial Number')
  echo "$HOST $SN (setup)"
 
  psql preflight -U preflight -c "UPDATE device SET graduated = NOW() WHERE id = '$SN'"
  psql preflight -U preflight -c "UPDATE device SET triton_uuid = '$HOST' WHERE id = '$SN'"
  psql preflight -U preflight -c "UPDATE device SET triton_setup = true WHERE id = '$SN'"
done

# If we're in Triton, but not setup, mark the CN as graduated and log the uuid.
for HOST in $( curl -s $SUBNET.0.44/servers | json -a uuid setup | grep false | awk '{print $1}' ); do
  SN=$( curl -s $SUBNET.0.44/servers/$HOST | json -a sysinfo.'Serial Number')
  echo "$HOST $SN (grad)"
 
  psql preflight -U preflight -c "UPDATE device SET triton_uuid = '$HOST' WHERE id = '$SN'"
  psql preflight -U preflight -c "UPDATE device SET graduated = NOW() WHERE id = '$SN'"
done
