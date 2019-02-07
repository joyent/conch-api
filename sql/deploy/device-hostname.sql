BEGIN;

    alter table device add column hostname text;

COMMIT;
