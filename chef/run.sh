#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin:/opt/dell/srvadmin/sbin

# We have no Internet access. This just confuses matters.
/usr/bin/perl -pi -e 's/^nameserver/#nameserver/' /etc/resolv.conf

make >> /var/log/chef.log 2>&1
