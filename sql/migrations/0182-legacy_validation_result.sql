SELECT run_migration(182, $$

  -- move aside old validation_results, preserving their contents

  -- validation_result -> legacy_validation_result
  alter table validation_result rename to legacy_validation_result;
  alter table validation_state_member rename column validation_result_id to legacy_validation_result_id;

  alter index validation_result_pkey rename to l_validation_result_pkey;
  alter index validation_result_all_columns_key rename to l_validation_result_all_columns_key;
  alter index validation_result_validation_id_idx rename to l_validation_result_validation_id_idx;

  alter table legacy_validation_result rename constraint validation_result_device_id_fkey to l_validation_result_device_id_fkey;
  alter table legacy_validation_result rename constraint validation_result_validation_id_fkey to l_validation_result_validation_id_fkey;

  -- validation_state_member -> legacy_validation_state_member
  alter table validation_state_member rename to legacy_validation_state_member;

  alter index validation_state_member_pkey rename to l_validation_state_member_pkey;
  alter index validation_state_member_validation_state_id_result_order_key rename to l_validation_state_member_validation_state_id_result_order_key;
  alter index validation_state_member_validation_result_id_idx rename to l_validation_state_member_legacy_validation_result_id_idx;

  alter table legacy_validation_state_member rename constraint validation_state_member_result_order_check to l_validation_state_member_result_order_check;
  alter table legacy_validation_state_member rename constraint validation_state_member_validation_result_id_fkey to l_validation_state_member_legacy_validation_result_id_fkey;
  alter table legacy_validation_state_member rename constraint validation_state_member_validation_state_id_fkey to l_validation_state_member_validation_state_id_fkey;

$$);
