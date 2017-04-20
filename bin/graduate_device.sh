#!/bin/bash

# Marks a device as "graduated" in the device table. This means it has moved to production.

if ! [ "$1" ] ; then
  "usage: $0 <SN>"
  exit 1
fi

SN=$1

psql preflight -U preflight -c "UPDATE device SET graduated = NOW() WHERE id = '$SN'"
