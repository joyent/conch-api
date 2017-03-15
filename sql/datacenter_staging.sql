INSERT INTO datacenter (id, vendor, vendor_name, region, location )
       VALUES ( ( select gen_random_uuid() ), 'Raging Wire', 'VA', 'east-1', 'Ashburn, VA, USA');

INSERT INTO datacenter_room (id, datacenter, az, alias, vendor_name)
       VALUES ( ( select gen_random_uuid() ), ( SELECT id FROM datacenter WHERE region = 'east-1' ), 'east-1c', 'AZ3', 'VA2.1');
