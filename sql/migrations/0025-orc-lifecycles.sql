SELECT run_migration(25, $$

create table workflow_lifecycle (
	id          uuid        primary key default gen_random_uuid(),
	name        text        not null,
	version     int         not null default 1,
	created     timestamptz not null default current_timestamp,
	updated     timestamptz not null default current_timestamp,
	deactivated timestamptz,
	locked      bool        not null default false,
	role_id     uuid        not null references device_role(id)
);
create unique index on workflow_lifecycle(name, version) where deactivated is null;


create table workflow_lifecycle_plan (
	lifecycle_id uuid not null references workflow_lifecycle (id),
	workflow_id  uuid not null references workflow (id),
	plan_order   int  not null,
	unique(lifecycle_id, workflow_id),
	unique(lifecycle_id, plan_order)
);


alter table workflow drop column product_id;
alter table workflow add column preflight bool default false;

$$);
