BEGIN;

    CREATE TABLE validation (
        id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
        name        TEXT        NOT NULL,
        version     INT         NOT NULL,
        description TEXT        NOT NULL,
        module      TEXT        NOT NULL,
        persistence BOOLEAN     NOT NULL DEFAULT FALSE,
        created     TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated     TIMESTAMPTZ NOT NULL DEFAULT now(),
        deactivated TIMESTAMPTZ,
        UNIQUE (name, version)
    );

    CREATE UNIQUE INDEX ON validation (module) WHERE deactivated IS NULL;

    CREATE TABLE validation_plan (
        id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
        name        TEXT        NOT NULL,
        description TEXT        NOT NULL,
        created     TIMESTAMPTZ NOT NULL DEFAULT now(),
        deactivated TIMESTAMPTZ
    );

    CREATE UNIQUE INDEX ON validation_plan (name) WHERE deactivated IS NULL;

    CREATE TABLE validation_plan_member (
        validation_id UUID NOT NULL REFERENCES validation(id),
        validation_plan_id UUID NOT NULL REFERENCES validation_plan(id),
        PRIMARY KEY (validation_id, validation_plan_id)
    );

    CREATE TYPE validation_status_enum AS ENUM ('error', 'pass', 'fail', 'processing');

    CREATE TABLE validation_state (
        id                 UUID                   PRIMARY KEY DEFAULT uuid_generate_v4(),
        device_id          TEXT                   NOT NULL REFERENCES device(id),
        validation_plan_id UUID                   NOT NULL REFERENCES validation_plan(id),
        created            TIMESTAMPTZ            NOT NULL DEFAULT now(),
        status             validation_status_enum NOT NULL DEFAULT 'processing',
        completed          TIMESTAMPTZ
    );

    -- IDEA: We could prevent multiple of the same validation plans executing
    -- simultaneously with following index:
    -- CREATE UNIQUE INDEX ON validation_state (device_id, validation_plan_id) WHERE completed IS NULL;

COMMIT;

