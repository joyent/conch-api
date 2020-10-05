SELECT run_migration(171, $$

    -- delete all old device_reports with no associated validation_state.
    -- (reports created before 2019-01-08 were not associated with validation_states, so we had to
    -- match them up as best we could based on similar timestamps, and not everyone found his
    -- match.)
    delete from device_report where id in (
      select device_report.id
      from device_report
      left join validation_state on validation_state.device_report_id = device_report.id
      where validation_state.id is null and device_report.created < (now() - interval '6 months')
    );

    -- delete all device_reports older than 6 months, except for the most recent
    -- report of each status type (error, fail, pass)
    delete from device_report where id in (
      select id from (
        select
          device_report.id,
          device_report.created,
          coalesce(
            case when count(distinct(validation_state.status)) > 1 then 'NOT_UNIQUE'
                else min(validation_state.status)::text end,
            'NONE') as status,
          row_number() over (
            partition by device_report.device_id, status order by device_report.created desc
          ) as seq
        from device_report
        left join validation_state on validation_state.device_report_id = device_report.id
        group by device_report.id, device_report.created, status
      ) _tmp
      where status != 'NOT_UNIQUE' and seq > 1 and created < (now() - interval '6 months')
    );

    -- now delete all (newly?) orphaned validation_result records
    delete from validation_result where id in (
      select validation_result.id
      from validation_result
      left join validation_state_member on validation_state_member.validation_result_id = validation_result.id
      where validation_state_member.validation_result_id is null
    );

$$);
