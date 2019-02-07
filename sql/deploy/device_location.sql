BEGIN;

    -- this is redundant - device_id is a primary key
    drop index device_location_device_id_idx;

    create index device_location_rack_id_idx on device_location (rack_id);

COMMIT;
