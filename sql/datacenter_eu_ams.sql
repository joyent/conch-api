INSERT INTO datacenter (vendor, vendor_name, region, location )
       VALUES ("Equinix", "AM1", "eu-ams-1", "Amsterdam, Netherlands");

INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'eu-ams-1' ), "eu-ams-1a", "AZ1", "AM1:01:310260");
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'eu-ams-1' ), "eu-ams-1b", "AZ2", "AM3:0G:010403");
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'eu-ams-1' ), "eu-ams-1c", "AZ3", "AM6:01:000Z3G");

