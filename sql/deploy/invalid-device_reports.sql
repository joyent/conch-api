BEGIN;

    alter table device_report
        alter report drop not null,
        add column invalid_report text default null;

COMMIT;
