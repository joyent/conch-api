BEGIN;

    -- Replace the index with one on 'device_id' and 'created' sorted.
    DROP INDEX device_report_device_id_idx;

    CREATE INDEX ON device_report (device_id, created DESC);

COMMIT;

