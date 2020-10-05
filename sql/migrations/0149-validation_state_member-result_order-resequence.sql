SELECT run_migration(149, $$

    update validation_state_member set result_order = result_seq - 1
    from (
      select
        validation_state_id,
        validation_result_id,
        row_number() over (
            partition by validation_state_id order by validation_result_id, result_order asc
        ) as result_seq
      from validation_state_member
      left join validation_result on validation_result.id = validation_state_member.validation_result_id
    ) _tmp
    where validation_state_member.validation_state_id = _tmp.validation_state_id
      and validation_state_member.validation_result_id = _tmp.validation_result_id;

$$);
