SELECT run_migration(139, $$

    update hardware_product_profile set nvme_ssd_num = 0 where nvme_ssd_num is null;
    update hardware_product_profile set raid_lun_num = 0 where raid_lun_num is null;
    update hardware_product_profile set sas_hdd_num = 0 where sas_hdd_num is null;
    update hardware_product_profile set sas_ssd_num = 0 where sas_ssd_num is null;
    update hardware_product_profile set sata_hdd_num = 0 where sata_hdd_num is null;
    update hardware_product_profile set sata_ssd_num = 0 where sata_ssd_num is null;
    update hardware_product_profile set psu_total = 0 where psu_total is null;

    alter table hardware_product_profile
        alter column nvme_ssd_num set default 0,
        alter column nvme_ssd_num set not null,
        alter column raid_lun_num set default 0,
        alter column raid_lun_num set not null,
        alter column sas_hdd_num set default 0,
        alter column sas_hdd_num set not null,
        alter column sas_ssd_num set default 0,
        alter column sas_ssd_num set not null,
        alter column sata_hdd_num set default 0,
        alter column sata_hdd_num set not null,
        alter column sata_ssd_num set default 0,
        alter column sata_ssd_num set not null,
        alter column psu_total set default 0,
        alter column psu_total set not null,
        alter column cpu_num set default 0,
        alter column dimms_num set default 0,
        alter column ram_total set default 0,
        alter column nics_num set default 0,
        alter column usb_num set default 0;

$$);
