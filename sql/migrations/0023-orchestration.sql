SELECT run_migration(23, $$

create table workflow (
	id          uuid        primary key default gen_random_uuid(),
	name        text        not null,
	version     int         not null default 1,
	created     timestamptz not null default current_timestamp,
	updated     timestamptz not null default current_timestamp,
	deactivated timestamptz,
	locked      bool        not null default false,
	product_id  uuid        not null references hardware_product (id),
	unique(name, version)
);
create unique index on workflow(name) where deactivated is null;

create type e_workflow_status as enum (
	'ongoing',
	'stopped',
	'abort',
	'resume',
	'completed',
	'restart'
);

create table workflow_status (
	id          uuid              primary key default gen_random_uuid(),
	workflow_id uuid              not null references workflow(id),
	device_id   text              not null references device(id),
	created     timestamptz       not null default current_timestamp,
	status      e_workflow_status not null default 'ongoing'
);

/*****************/

create table workflow_step (
	id                 uuid primary key default gen_random_uuid(),
	created            timestamptz not null default current_timestamp,
	updated            timestamptz not null default current_timestamp,
	workflow_id        uuid not null references workflow(id),
	name               text not null,
	step_order         int not null,
	retry              bool default false,
	max_retries        int not null default 1,
	validation_plan_id uuid not null references validation_plan(id),
	unique(name, workflow_id)
);

/*****************/

create type e_workflow_step_state as enum (
	'started',
	'processing',
	'complete'
);

create type e_workflow_validation_status as enum (
	'pass',
	'fail',
	'error',
	'processing',
	'noop'
);

create table workflow_step_status(
	id                   uuid primary key default gen_random_uuid(),
	created              timestamptz not null default current_timestamp,
	updated              timestamptz not null default current_timestamp,
	device_id            text not null references device(id),
	workflow_step_id     uuid not null references workflow_step(id),
	state                e_workflow_step_state not null default 'processing',
	retry_count          int not null default 1,
	validation_status    e_workflow_validation_status not null default 'noop',
	validation_state_id  uuid references validation_state(id),
	force_retry          bool default false,
	overridden           bool default false,
	data                 jsonb
);

$$);
