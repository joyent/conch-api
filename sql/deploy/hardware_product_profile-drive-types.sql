BEGIN;

    alter table hardware_product_profile rename column sata_num to sata_hdd_num;
    alter table hardware_product_profile rename column sata_size to sata_hdd_size;
    alter table hardware_product_profile rename column sata_slots to sata_hdd_slots;
    alter table hardware_product_profile rename column sas_num to sas_hdd_num;
    alter table hardware_product_profile rename column sas_size to sas_hdd_size;
    alter table hardware_product_profile rename column sas_slots to sas_hdd_slots;
    alter table hardware_product_profile rename column ssd_num to sata_ssd_num;
    alter table hardware_product_profile rename column ssd_size to sata_ssd_size;
    alter table hardware_product_profile rename column ssd_slots to sata_ssd_slots;
    alter table hardware_product_profile add column sas_ssd_num integer;
    alter table hardware_product_profile add column sas_ssd_size integer;
    alter table hardware_product_profile add column sas_ssd_slots text;
    alter table hardware_product_profile add column nvme_ssd_num integer;
    alter table hardware_product_profile add column nvme_ssd_size integer;
    alter table hardware_product_profile add column nvme_ssd_slots text;
    alter table hardware_product_profile add column raid_lun_num integer;

COMMIT;
