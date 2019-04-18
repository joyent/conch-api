SELECT run_migration(91, $$

    alter table rack add column phase device_phase_enum default 'integration' not null;

$$);
