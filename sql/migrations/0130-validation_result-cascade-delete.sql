SELECT run_migration(130, $$

   alter table validation_state_member
        drop constraint validation_state_member_validation_result_id_fkey,
        add constraint validation_state_member_validation_result_id_fkey
            foreign key (validation_result_id) references validation_result (id) on delete cascade;

$$);
