BEGIN;

    alter type validation_status_enum rename to _validation_status_enum_old;

    create type validation_status_enum as enum ('error','fail','processing','pass');

    alter table validation_result
        alter column status type validation_status_enum using status::text::validation_status_enum;

    alter table validation_state
        alter column status drop default,
        alter column status type validation_status_enum using status::text::validation_status_enum;

    drop type _validation_status_enum_old;

COMMIT;
