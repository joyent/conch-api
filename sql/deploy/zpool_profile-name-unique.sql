BEGIN;

    update zpool_profile
        set deactivated = now()
        where name = 'Joyent-Compute-Platform-3302'
        and id not in (select zpool_id from hardware_product_profile where zpool_id is not null);

    create unique index zpool_profile_name_key on zpool_profile (name) where deactivated is null;

COMMIT;
