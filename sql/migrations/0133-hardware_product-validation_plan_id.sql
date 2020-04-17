SELECT run_migration(133, $$

    alter table hardware_product add column validation_plan_id uuid
        default null references validation_plan (id);

    -- first, assert that we're not going to get into trouble later on...
    do $inner$ begin
        assert
            (select count(*) from (
                select
                    device.hardware_product_id,
                    count(distinct validation_plan_id) as count
                    from validation_state
                    left join device on device.id = validation_state.device_id
                    left join validation_plan on validation_plan.id = validation_state.validation_plan_id
                    where validation_plan.name != 'Conch device_validate results placeholder'
                    group by device.hardware_product_id
                ) tmp1
                where count > 1)
            = 0,
        'validation_plan_id <-> hardware_product correlation is not 1:1';
    end; $inner$;

    -- first, backfill validation_plan_id using historical results using the
    -- common hardware_products and the two validation_plans
    update hardware_product
        set validation_plan_id = validation_state.validation_plan_id
        from device
        inner join validation_state on validation_state.device_id = device.id
        inner join validation_plan on validation_plan.id = validation_state.validation_plan_id
        where device.hardware_product_id = hardware_product.id
            and validation_plan.name != 'Conch device_validate results placeholder';

    -- now fill in the remaining hardware_products, associated with devices
    -- that only have representation in the old device_validate records that
    -- were backfilled in the v2.24.0 release (see PR#669)
    update hardware_product
        set validation_plan_id = validation_state.validation_plan_id
        from device
        inner join validation_state on validation_state.device_id = device.id
        where device.hardware_product_id = hardware_product.id
            and hardware_product.validation_plan_id is null;

    -- now create a placeholder validation_plan to use in all the remaining
    -- hardware_products that have no historical validation results at all
    with new_plan as (
        insert into validation_plan (name, description)
        values (
            'Conch hardware_product.validation_plan_id placeholder',
            'plan to link to legacy hardware_product entries (conch v2->v3 update)'
        ) returning id
    )
    update hardware_product
        set validation_plan_id = (select id from new_plan)
        where hardware_product.validation_plan_id is null;

    -- now that all rows have their validation_plan_id populated, we can set this not-nullable!
    alter table hardware_product alter column validation_plan_id set not null;

$$);
