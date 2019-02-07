BEGIN;
	alter table datacenter drop column deactivated;
	alter table datacenter_room drop column deactivated;

	drop table datacenter_room_network;
	drop table datacenter_network;
COMMIT;

