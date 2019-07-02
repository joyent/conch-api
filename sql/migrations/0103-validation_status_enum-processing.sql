SELECT run_migration(103, $$

    -- remove the 'processing' value from validation_status_enum:
    -- this is an old state that validation_states would be initially created under,
    -- and then status would be updated later, with completed=now().

    -- transform all validation_result entries with status = 'processing' to 'error'
    -- (although we do not expect there actually are any such rows)
    update validation_result
        set status = 'error'
        where status = 'processing';

    -- for all validation_state rows with status = 'processing',
    -- use the worst status of all its result member(s).

    update validation_state set status = 'error'
    from validation_state_member
    left join validation_result on validation_result.id = validation_state_member.validation_result_id
    where
        validation_state.status = 'processing'
        and validation_state_member.validation_state_id = validation_state.id
        and validation_result.status = 'error';

    update validation_state set status = 'fail'
    from validation_state_member
    left join validation_result on validation_result.id = validation_state_member.validation_result_id
    where
        validation_state.status = 'processing'
        and validation_state_member.validation_state_id = validation_state.id
        and validation_result.status = 'fail';

    update validation_state set status = 'pass'
    from validation_state_member
    left join validation_result on validation_result.id = validation_state_member.validation_result_id
    where
        validation_state.status = 'processing'
        and validation_state_member.validation_state_id = validation_state.id
        and validation_result.status = 'pass';

    -- now there should be no validation_state rows remaining with status = 'processing'
    -- except those with no associated members at all -- the best we can do is to call
    -- that result an 'error', so we can continue to preserve the associated device_report.

    update validation_state set status = 'error' where status = 'processing';

    -- now we can safely remove 'processing' as one of the values for the enum.

    alter type validation_status_enum rename to _validation_status_enum_old;
    create type validation_status_enum as enum ('error','fail','pass');
    alter table validation_result
        alter column status type validation_status_enum using status::text::validation_status_enum;
    alter table validation_state
        alter column status type validation_status_enum using status::text::validation_status_enum;
    drop type _validation_status_enum_old;

    -- also set 'completed' for all these records, and make it not-nullable.

    update validation_state
        set completed = greatest(validation_state.created, device_report.created)
        from device_report
        where device_report.id = validation_state.device_report_id
            and validation_state.completed is null;

    alter table validation_state alter completed set not null;
    drop index validation_state_device_id_validation_plan_id_completed_idx;
    create index validation_state_device_id_validation_plan_id_completed_idx on validation_state
        (device_id, validation_plan_id, completed desc);

$$);
