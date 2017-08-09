BEGIN;

CREATE TABLE migration (
    id         serial      PRIMARY KEY,
    date_created timestamptz DEFAULT current_timestamp
);

COMMIT;
