INSERT INTO datacenter (vendor, vendor_name, region, location )
       VALUES ("Equinix", "AM", "eu-central-1", "Amsterdam, Netherlands");

INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'eu-central-1' ), "eu-central-1a", "AZ1", "AM1");
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'eu-central-1' ), "eu-central-1b", "AZ2", "AM3");
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'eu-central-1' ), "eu-central-1c", "AZ3", "AM6");
