SELECT run_migration(183, $$

  -- validation -> legacy_validation
  alter table validation rename to legacy_validation;
  alter table legacy_validation_result rename column validation_id to legacy_validation_id;

  alter index validation_module_idx rename to l_validation_module_idx;
  alter index validation_name_version_key rename to l_validation_name_version_key;
  alter table legacy_validation rename constraint validation_pkey to l_validation_pkey;
  alter table legacy_validation rename constraint validation_version_check to l_validation_version_check;

  -- validation_plan -> legacy_validation_plan

  alter table validation_plan rename to legacy_validation_plan;
  alter table hardware_product rename column validation_plan_id to legacy_validation_plan_id;
  alter table validation_plan_member rename column validation_plan_id to legacy_validation_plan_id;
  alter table validation_plan_member rename column validation_id to legacy_validation_id;

  alter index validation_plan_member_validation_plan_id_idx rename to l_validation_plan_member_legacy_validation_plan_id_idx;
  alter index validation_plan_name_idx rename to l_validation_plan_name_idx;
  alter table legacy_validation_plan rename constraint validation_plan_pkey to l_validation_plan_pkey;
  alter table hardware_product rename constraint hardware_product_validation_plan_id_fkey to hardware_product_legacy_validation_plan_id_fkey;

  -- validation_plan_member -> legacy_validation_plan_member
  alter table validation_plan_member rename to legacy_validation_plan_member;

  alter table legacy_validation_plan_member rename constraint validation_plan_member_pkey to l_validation_plan_member_pkey;
  alter table legacy_validation_plan_member rename constraint validation_plan_member_validation_id_fkey to l_validation_plan_member_legacy_validation_id_fkey;
  alter table legacy_validation_plan_member rename constraint validation_plan_member_validation_plan_id_fkey to l_validation_plan_member_legacy_validation_plan_id_fkey;

$$);
