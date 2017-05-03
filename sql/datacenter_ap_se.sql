INSERT INTO datacenter (vendor, vendor_name, region, location )
       VALUES ('Equinix', 'SG', 'ap-southeast-1', 'Singapore');

INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'ap-southeast-1' ), 'ap-southeast-1a', 'AZ1', 'SG3 4-4');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'ap-southeast-1' ), 'ap-southeast-1b', 'AZ2', 'SG3 6-4');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'ap-southeast-1' ), 'ap-southeast-1c', 'AZ3', 'SG2 4-7');
