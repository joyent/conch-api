SELECT run_migration(101, $$

    -- migration numbers are always manually selected; this sequence serves no purpose.
    alter table migration alter column id drop default;
    drop sequence migration_id_seq;

$$);
