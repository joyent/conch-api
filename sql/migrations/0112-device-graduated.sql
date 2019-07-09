SELECT run_migration(112, $$

    update device set phase = 'production', updated = now()
        where graduated is not null and phase < 'production';

    alter table device drop column graduated;

$$);
