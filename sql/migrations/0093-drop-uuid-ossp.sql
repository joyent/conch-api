SELECT run_migration(94, $$

    alter table validation alter column id set default gen_random_uuid();
    alter table validation_plan alter column id set default gen_random_uuid();
    alter table validation_result alter column id set default gen_random_uuid();
    alter table validation_state alter column id set default gen_random_uuid();
    alter table workspace alter column id set default gen_random_uuid();

    -- sadly, we can't do this in a migration:
    -- "ERROR:  must be owner of extension uuid-ossp"
    -- drop extension "uuid-ossp";

$$);
