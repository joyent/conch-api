SELECT run_migration(140, $$

    alter table hardware_product
        add column purpose text,
        add column bios_firmware text,
        add column hba_firmware text,
        add column cpu_num integer default 0,
        add column cpu_type text,
        add column dimms_num integer default 0,
        add column ram_total integer default 0,
        add column nics_num integer default 0,
        add column sata_hdd_num integer default 0,
        add column sata_hdd_size integer,
        add column sata_hdd_slots text,
        add column sas_hdd_num integer default 0,
        add column sas_hdd_size integer,
        add column sas_hdd_slots text,
        add column sata_ssd_num integer default 0,
        add column sata_ssd_size integer,
        add column sata_ssd_slots text,
        add column psu_total integer default 0,
        add column usb_num integer default 0,
        add column sas_ssd_num integer default 0,
        add column sas_ssd_size integer,
        add column sas_ssd_slots text,
        add column nvme_ssd_num integer default 0,
        add column nvme_ssd_size integer,
        add column nvme_ssd_slots text,
        add column raid_lun_num integer default 0;

    update hardware_product set
            purpose          = hardware_product_profile.purpose,
            bios_firmware    = hardware_product_profile.bios_firmware,
            hba_firmware     = hardware_product_profile.hba_firmware,
            cpu_num          = hardware_product_profile.cpu_num,
            cpu_type         = hardware_product_profile.cpu_type,
            dimms_num        = hardware_product_profile.dimms_num,
            ram_total        = hardware_product_profile.ram_total,
            nics_num         = hardware_product_profile.nics_num,
            sata_hdd_num     = hardware_product_profile.sata_hdd_num,
            sata_hdd_size    = hardware_product_profile.sata_hdd_size,
            sata_hdd_slots   = hardware_product_profile.sata_hdd_slots,
            sas_hdd_num      = hardware_product_profile.sas_hdd_num,
            sas_hdd_size     = hardware_product_profile.sas_hdd_size,
            sas_hdd_slots    = hardware_product_profile.sas_hdd_slots,
            sata_ssd_num     = hardware_product_profile.sata_ssd_num,
            sata_ssd_size    = hardware_product_profile.sata_ssd_size,
            sata_ssd_slots   = hardware_product_profile.sata_ssd_slots,
            psu_total        = hardware_product_profile.psu_total,
            usb_num          = hardware_product_profile.usb_num,
            sas_ssd_num      = hardware_product_profile.sas_ssd_num,
            sas_ssd_size     = hardware_product_profile.sas_ssd_size,
            sas_ssd_slots    = hardware_product_profile.sas_ssd_slots,
            nvme_ssd_num     = hardware_product_profile.nvme_ssd_num,
            nvme_ssd_size    = hardware_product_profile.nvme_ssd_size,
            nvme_ssd_slots   = hardware_product_profile.nvme_ssd_slots,
            raid_lun_num     = hardware_product_profile.raid_lun_num,
            created          = least(hardware_product.created, hardware_product_profile.created),
            updated          = greatest(hardware_product.updated, hardware_product_profile.updated),
            deactivated      = least(hardware_product.deactivated, hardware_product_profile.deactivated)
        from hardware_product_profile
        where hardware_product_profile.hardware_product_id = hardware_product.id;

    alter table hardware_product
        alter column purpose set not null,
        alter column bios_firmware set not null,
        alter column cpu_num set not null,
        alter column cpu_type set not null,
        alter column dimms_num set not null,
        alter column ram_total set not null,
        alter column nics_num set not null,
        alter column sata_hdd_num set not null,
        alter column sas_hdd_num set not null,
        alter column sata_ssd_num set not null,
        alter column psu_total set not null,
        alter column usb_num set not null,
        alter column sas_ssd_num set not null,
        alter column nvme_ssd_num set not null,
        alter column raid_lun_num set not null;

    drop table hardware_product_profile;

$$);
