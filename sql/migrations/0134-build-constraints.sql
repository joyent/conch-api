SELECT run_migration(134, $$

    alter table build
        add constraint build_completed_iff_started_check check
            (completed is null or started is not null);

    alter table build
        add constraint build_completed_xnor_completed_user_id_check check
            ((completed is null and completed_user_id is null) or (completed is not null and completed_user_id is not null));

$$);
