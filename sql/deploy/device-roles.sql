BEGIN;

create table device_service (
	id   uuid primary key default gen_random_uuid(),
	name text not null unique,

	created     timestamptz not null default current_timestamp,
	updated     timestamptz not null default current_timestamp
);


create table device_role (
	id                  uuid primary key default gen_random_uuid(),
	description         text,
	hardware_product_id uuid not null references hardware_product(id),

	created     timestamptz not null default current_timestamp,
	updated     timestamptz not null default current_timestamp,
	deactivated timestamptz
);

create table device_role_services(
	role_id     uuid not null references device_role(id),
	service_id  uuid not null references device_service(id),

	unique (role_id, service_id)
);


alter table device drop column role;
alter table device add column role uuid references device_role(id);

COMMIT;
