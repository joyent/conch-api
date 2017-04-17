#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin:/opt/dell/srvadmin/sbin

while true ; do
  cd /var/chef
  make >> /var/log/chef.log 2>&1

  sleep 300
done
