SELECT run_migration(23, $$

create table workflow (
	id          uuid        primary key default gen_random_uuid(),
	name        text        not null unique,
	version     int         not null default 1,
	created     timestamptz not null default current_timestamp,
	updated     timestamptz not null default current_timestamp,
	deactivated timestamptz,
	locked      bool        not null default false,
	preflight   bool        default false,
	unique(name, version)
);

/*****************/

create table orc_lifecycle (
	id          uuid        primary key default gen_random_uuid(),
	name        text        not null unique,
	version     int         not null default 1,
	device_role text        not null,
	product_id uuid        not null references hardware_product (id),

	created     timestamptz not null default current_timestamp,
	updated     timestamptz not null default current_timestamp,
	deactivated timestamptz,
	locked      bool        not null default false,
	unique(name),
	unique(name, version),
	unique(name, version, device_role, product_id)
);

create table orc_lifecycle_plan (
	orc_lifecycle_id uuid  not null references orc_lifecycle (id),
	workflow_id      uuid  not null references workflow (id),
	workflow_order   int   not null,
	unique(orc_lifecycle_id, workflow_id),
	unique(orc_lifecycle_id, workflow_order)
);

/*****************/

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
	timestamp   timestamptz       not null default current_timestamp,
	status      e_workflow_status not null default 'ongoing'
);

/*****************/

create table workflow_step (
	id                 uuid primary key default gen_random_uuid(),
	created            timestamptz not null default current_timestamp,
	updated            timestamptz not null default current_timestamp,
	deactivated        timestamptz,
	workflow_id        uuid not null references workflow(id),
	name               text not null,
	step_order         int not null,
	retry              bool default false,
	max_retries        int not null default 1,
	validation_plan_id uuid not null, -- fk to real tables when they exist
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
	validation_result_id uuid, -- fk to real tables when they exist
	force_retry          bool default false,
	overridden            bool default false,
	data                 jsonb
);

/*****************/

create or replace view orc_latest_workflow_status as
select * from (
	select *, dense_rank() over (
		partition by workflow_id
		order by timestamp desc
	) as workflow_rank
	from workflow_status
) as ranked_workflows
where workflow_rank = 1;

$$);
