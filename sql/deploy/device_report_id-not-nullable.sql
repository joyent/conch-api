BEGIN;

    update validation_state
        set device_report_id =
            (select device_report.id from device_report
            join device on device.id = validation_state.device_id
            where device_report.created <= validation_state.completed
            order by device_report.created desc limit 1)
        where device_report_id is null and validation_state.completed is not null;

    update validation_state
        set device_report_id =
            (select device_report.id from device_report
            join device on device.id = validation_state.device_id
            where device_report.created <= validation_state.created
            order by device_report.created desc limit 1)
        where device_report_id is null and validation_state.completed is null;

    alter table validation_state alter device_report_id set not null;

COMMIT;
