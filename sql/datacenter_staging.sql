INSERT INTO datacenter (vendor, vendor_name, region, location )
       VALUES ( 'Raging Wire', 'VA', 'east-1', 'Ashburn, VA, USA');

INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'east-1' ), 'east-1c', 'AZ3', 'VA2.1');
