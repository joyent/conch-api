BEGIN;

    alter table datacenter_rack
        add column serial_number text,
        add column asset_tag text;

COMMIT;
