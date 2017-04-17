update device_neighbor set want_switch = 'va2-1-e02-1-test' where mac = '24:6e:96:23:e8:fa';
update device_neighbor set want_port = '1/36' where mac = '24:6e:96:23:e8:fa';

update device_neighbor set want_switch = 'va2-1-e02-2-test' where mac = 'a0:36:9f:c1:99:1e';
update device_neighbor set want_port = '1/36' where mac = 'a0:36:9f:c1:99:1e';

update device_neighbor set want_switch = 'va2-1-e02-1-test' where mac = '24:6e:96:23:e8:f8';
update device_neighbor set want_port = '1/17' where mac = '24:6e:96:23:e8:f8';

update device_neighbor set want_switch = 'va2-1-e02-2-test' where mac = 'a0:36:9f:c1:99:1c';
update device_neighbor set want_port = '1/17' where mac = 'a0:36:9f:c1:99:1c';


