SELECT run_migration(171, $$

    -- create a placeholder validation_state record for every device_report without a
    -- validation_state record pointing to it
    -- (reports created before 2019-01-08 were not associated with validation_states, so we had to
    -- match them up as best we could based on similar timestamps, and not everyone found his
    -- match.)
    insert into validation_state (validation_plan_id, created, status, device_report_id, device_id, hardware_product_id)
    (
      select
        hardware_product.validation_plan_id,
        device_report.created,
        'error',
        device_report.id,
        device_report.device_id,
        device.hardware_product_id
      from device_report
      left join validation_state on validation_state.device_report_id = device_report.id
      left join device on device_report.device_id = device.id
      left join hardware_product on hardware_product.id = device.hardware_product_id
      where validation_state.id is null
    );

    -- now we can run bin/conch thin_device_reports, which will delete all device_report rows
    -- (cascading to validation_state, validation_state_member) which are older than six months,
    -- except for the most recent report of each validation status (error, fail, pass)..
    -- and then delete newly-orphaned validation_result rows.

$$);
