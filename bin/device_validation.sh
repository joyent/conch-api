#!/bin/bash

if ! [ "$1" ] ; then
  "usage: $0 <SN>"
  exit 1
fi

SN=$1

if [ "$2" ] ; then
  STATUS="and status = $2"
fi


REPORT_ID=$( psql -q -t -A -d preflight -U preflight -c "select report_id from device_validate where device_id = '$SN' order by created desc limit 1" )
psql -d preflight -U preflight -c "select device_id,report_id,component_type,component_name,metric,log,status,created from device_validate where report_id = '$REPORT_ID' $STATUS order by created desc"
