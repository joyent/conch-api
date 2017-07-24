INSERT INTO datacenter (vendor, vendor_name, region, location )
       VALUES ( 'Solar Cognition', 'Mars', 'arcadia-planitia-1', 'Arcadia Planitia, Tharsis, Mars');

INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'arcadia-planitia-1' ), 'arcadia-planitia-1a', 'AZ1', 'MARS1.1');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'arcadia-planitia-1' ), 'arcadia-planitia-1b', 'AZ2', 'MARS1.2');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'arcadia-planitia-1' ), 'arcadia-planitia-1c', 'AZ3', 'MARS1.3');

INSERT INTO datacenter (vendor, vendor_name, region, location )
       VALUES ( 'Solar Cognition', 'Mars', 'hellas-planitia-1', 'Hellas Planitia, Hellas, Mars');

INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'hellas-planitia-1' ), 'hellas-planitia-1a', 'AZ1', 'MARS2.1');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'hellas-planitia-1' ), 'hellas-planitia-1b', 'AZ2', 'MARS2.2');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'hellas-planitia-1' ), 'hellas-planitia-1c', 'AZ3', 'MARS2.3');

INSERT INTO datacenter (vendor, vendor_name, region, location )
       VALUES ( 'Solar Cognition', 'Neptune', 'halimede-1', 'Halimede, Retrograde Orbit, Neptune System');

INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'halimede-1' ), 'halimede-1a', 'AZ1', 'NEPTUNE1.1');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'halimede-1' ), 'halimede-1b', 'AZ2', 'NEPTUNE1.2');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'halimede-1' ), 'halimede-1c', 'AZ3', 'NEPTUNE1.3');

INSERT INTO datacenter (vendor, vendor_name, region, location )
       VALUES ( 'Solar Cognition', 'Neptune', 'psamathe-1', 'Psamathe, Retrograde Orbit, Neptune System');

INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'psamathe-1' ), 'psamathe-1a', 'AZ1', 'NEPTUNE2.1');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'psamathe-1' ), 'psamathe-1b', 'AZ2', 'NEPTUNE2.2');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'psamathe-1' ), 'psamathe-1c', 'AZ3', 'NEPTUNE2.3');

INSERT INTO datacenter (vendor, vendor_name, region, location )
       VALUES ( 'Solar Cognition', 'Neptune', 'neso-1', 'Neso, Retrograde Orbit, Neptune System');

INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'neso-1' ), 'neso-1a', 'AZ1', 'NEPTUNE3.1');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'neso-1' ), 'neso-1b', 'AZ2', 'NEPTUNE3.3');
INSERT INTO datacenter_room (datacenter, az, alias, vendor_name)
       VALUES ( ( SELECT id FROM datacenter WHERE region = 'neso-1' ), 'neso-1c', 'AZ3', 'NEPTUNE3.2');
