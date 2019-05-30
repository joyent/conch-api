SELECT run_migration(102, $$

    alter table validation alter column id set default gen_random_uuid();
    alter table validation_plan alter column id set default gen_random_uuid();
    alter table validation_result alter column id set default gen_random_uuid();
    alter table validation_state alter column id set default gen_random_uuid();
    alter table workspace alter column id set default gen_random_uuid();

    drop extension "uuid-ossp";

$$);
