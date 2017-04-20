#!/bin/bash

if ! [ "$1" ] ; then
  "usage: $0 <SN>"
  exit 1
fi

SN=$1

echo "$SN: Marking graduated to production"
psql preflight -U preflight -c "select device_id,component_type,component_name,metric,log,status,created from device_validate where device_id = '$SN' order by created"
