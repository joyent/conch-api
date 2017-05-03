From a preflight image:

* drop database preflight
* create database preflight with owner preflight
* data_region_racks.txt
* data_region.sql
* data_region.sh
* grep region misc/RegionPorts.all > misc/azPorts.out
* ./bin/load_datacenter.pl misc/azPorts.out
* Update /opt/conch/Conch/conch.conf
* /root/run_conch.sh

