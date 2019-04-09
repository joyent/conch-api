SELECT run_migration(90, $$

    alter type device_phase_enum rename to _device_phase_enum_old;

    create type device_phase_enum as enum ('integration','installation','production','diagnostics','decommissioned');

    alter table device
        alter column phase drop default,
        alter column phase type device_phase_enum using phase::text::device_phase_enum,
        alter column phase set default 'integration';

    drop type _device_phase_enum_old;

$$);

