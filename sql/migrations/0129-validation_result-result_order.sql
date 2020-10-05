SELECT run_migration(129, $$

    -- In order to speed up deployment time (this migration file takes many
    -- tens of hours to run on a production database), we drop all historical
    -- validation_results. The overall outcome of all the validations is still
    -- captured in validation_state.status.  If it is desired to later load
    -- that historical data back into the database, start with a backup of
    -- production-v2, delete the following two lines from this file, and run
    -- all migrations against that database, then copy the validation_state_member
    -- and validation_result tables into the master database:
    -- pg_dump -U postgres -t validation_result -t validation_state_member source_database | psql -U conch conch

    -- ..but before we do that, we need to copy hardware_product_id to validation_state
    -- for all historical records...

    alter table validation_state add column hardware_product_id uuid references hardware_product (id);

    update validation_state set hardware_product_id = result_hardware_product_id
    from (
      select
        validation_state_id,
        validation_result.hardware_product_id as result_hardware_product_id,
        row_number() over (partition by validation_state_id order by result_order asc) as result_num
      from validation_state
      left join validation_state_member on validation_state.id = validation_state_member.validation_state_id
      left join validation_result on validation_result.id = validation_state_member.validation_result_id
    ) _tmp
    where result_num = 1
      and validation_state.id = validation_state_id;

    select count(*) from validation_state where hardware_product_id is null;

    update validation_state set hardware_product_id = device.hardware_product_id
    from device
    where validation_state.device_id = device.id
      and validation_state.hardware_product_id is null;

    -- this should now be zero.
    select count(*) from validation_state where hardware_product_id is null;


    alter table validation_state alter column hardware_product_id set not null;
    create index validation_state_hardware_product_id_idx on validation_state (hardware_product_id);

    -- this never worked without superuser privileges
    -- \copy validation_result to '/mnt/tmp/validation_result_bak_pre_v3.sql';
    -- \copy validation_state_member to '/mnt/tmp/validation_state_member_bak_pre_v3.sql';

    -- keep all the results, and continue to restructure them in subsequent migration queries
    -- truncate validation_state_member, validation_result;


    -- these are the two validation modules that can produce duplicate
    -- results, with the exception of the result_order.  For cpu_temperature
    -- at least, we can infer the component value; for switch_peers we cannot
    -- as there are multiple sections of result generation, which can fire in
    -- an unpredictable order due to hash ordering of the 'interface' section
    -- of the device report.
    update validation_result
        set component='cpu'||result_order
        from validation
        where validation_result.validation_id = validation.id
            and validation.name = 'cpu_temperature'
            and validation_result.component is null;

    update validation_result
        set component='unknown'||result_order
        from validation
        where validation_result.validation_id = validation.id
            and validation.name = 'switch_peers'
            and validation_result.component is null;


    alter table validation_state_member
        add column result_order integer default 0 not null check (result_order >= 0);

    update validation_state_member
        set result_order = validation_result.result_order
        from validation_result
        where validation_state_member.validation_result_id = validation_result.id;

    alter table validation_state_member alter column result_order drop default;
    alter table validation_result drop column result_order;

    drop index if exists validation_result_all_columns_idx;
    -- note that migration 0144 later changes this to a unique constraint
    create index validation_result_all_columns_idx on validation_result
        (device_id, hardware_product_id, validation_id, message, hint, status, category, component);

$$);
