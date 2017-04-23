#!/bin/bash -x

TO_SLEEP=$[ ( $RANDOM % 30 )  + 1 ]
sleep ${TO_SLEEP}s
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin:/opt/dell/srvadmin/sbin /var/preflight/bin/export.pl > /var/preflight/log/export.log 2>&1
