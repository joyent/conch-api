SELECT run_migration(88, $$

    create type device_phase_enum as enum ('integration','production','diagnostics','decommissioned');
    alter table device add column phase device_phase_enum default 'integration' not null;

$$);
