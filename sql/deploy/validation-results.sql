BEGIN;

	create table validation_result (
		id                  uuid                   primary key default uuid_generate_v4(),
		device_id           text                   not null references device(id),
		hardware_product_id uuid                   not null references hardware_product(id),
		validation_id       uuid                   not null references validation(id),
		message             text                   not null,
		hint                text,
		status              validation_status_enum not null,
		category            text                   not null,
		component_id        text,
		result_order        int                    not null,
		created             timestamptz            not null default now()
	);

	create table validation_state_member (
		validation_state_id  uuid not null references validation_state(id),
		validation_result_id uuid not null references validation_result(id),
		primary key(validation_state_id, validation_result_id)
	);

    -- not used or needed
    alter table validation drop column persistence;

COMMIT;

