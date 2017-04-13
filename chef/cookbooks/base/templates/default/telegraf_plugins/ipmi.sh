#!/bin/sh
###
# ABOUT  : telegraf monitoring script for ipmi statistics
# AUTHOR : Matthias Breddin <mb@lunetics.com> (c) 2015
# LICENSE: GNU GPL v3
#
# This script parses the "ipmitool sensor" output for available data
# Generates output suitable for Exec plugin of telegraf.
#
# Requirements:
#   ipmitool binary:
#       Freebsd: /usr/local/bin/ipmitool
#       Linux: /usr/bin
#   sudo entry for binary (ie. for sys account):
#       sys   ALL = (root) NOPASSWD: /usr/local/sbin/ipmitool
#
#
# Typical usage:
#   /usr/local/telegraf-plugins/ipmi/ipmi.sh
#
# Typical output:
#  ipmi,host=host.foo.com,type=temperature,instance=System\ Temp value=60.0000
#  ipmi,host=host.foo.com,type=voltage,instance=CPU1\ Vcore value=0.9600
#  ipmi,host=host.foo.com,type=voltage,instance=CPU2\ Vcore value=0.9760
#  ipmi,host=host.foo.com,type=voltage,instance=+5V value=5.1520
#  ipmi,host=host.foo.com,type=voltage,instance=+5VSB value=5.1200
#  ipmi,host=host.foo.com,type=voltage,instance=+12V value=12.1370
#  ipmi,host=host.foo.com,type=voltage,instance=-12V value=-11.8040
#  ipmi,host=host.foo.com,type=voltage,instance=+3.3V value=3.2400
#  ipmi,host=host.foo.com,type=voltage,instance=+3.3VSB value=3.2640
#  ipmi,host=host.foo.com,type=voltage,instance=VBAT value=3.2160
#  ipmi,host=host.foo.com,type=fan,instance=Fan1 value=8370.0000
#  ipmi,host=host.foo.com,type=fan,instance=Fan2 value=8370.0000
#  ipmi,host=host.foo.com,type=fan,instance=Fan3 value=8370.0000
#  ipmi,host=host.foo.com,type=fan,instance=Fan4 value=8370.0000
#  ipmi,host=host.foo.com,type=temperature,instance=P1-DIMM1A\ Temp value=38.0000
#  ipmi,host=host.foo.com,type=temperature,instance=P1-DIMM2A\ Temp value=39.0000
#  ipmi,host=host.foo.com,type=temperature,instance=P1-DIMM3A\ Temp value=40.0000
#  ipmi,host=host.foo.com,type=temperature,instance=P2-DIMM1A\ Temp value=34.0000
#  ipmi,host=host.foo.com,type=temperature,instance=P2-DIMM2A\ Temp value=35.0000
#  ipmi,host=host.foo.com,type=temperature,instance=P2-DIMM3A\ Temp value=34.0000

# ...
#
###
PATH=$PATH:/bin:/usr/bin/:/usr/local/bin/:/usr/local/sbin
`which sudo` `which ipmitool` sensor \
| awk -v hostname=<%= @serial_number %> -F'|' 'tolower($3) ~ /(volt|rpm|watt|degree)/ && $2 !~ /na/ {
            if (tolower($3) ~ /volt/) type="voltage";
            if (tolower($3) ~ /rpm/)  type="fan";
            if (tolower($3) ~ /watt/) type="power";
            if (tolower($3) ~ /degree/) type="temperature";
            if (tolower($3) ~ /watts/) type="power";
            if (tolower($3) ~ /units/) type="current";
            gsub(/[ \t]*$/,"",$1);
            gsub(/[ ]/,"\\\ ",$1);
            gsub(/,/,"\,", $1);
            print "ipmi,host="hostname",type="type",instance="$1" value="sprintf("%.4f",$2);
        }'
