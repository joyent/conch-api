-- conch schema

-- Questions to ask for each column:
-- NOT NULL?
-- UNIQUE?
-- REFERENCES?
-- ON (DELETE | UPDATE)
-- DEFAULT value?
-- Indexed?

-- Questions to ask for each table
-- Normalization:
--   * are all rows completely defined wholly and only by the primary key?
-- What fields do we need to keep track of their updated time?

-- Run this as superuser:
-- CREATE EXTENSION pgcrypto;

CREATE TABLE datacenter (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor              text        NOT NULL, -- Raging Wire
    vendor_name         text,                 -- VA1
    region              text        NOT NULL, -- us-east1
    location            text        NOT NULL, -- Ashburn, VA, USA
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE datacenter_room (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    datacenter          uuid        NOT NULL REFERENCES datacenter (id),
    az                  text        NOT NULL, -- us-east-1b
    alias               text,                 -- AZ1
    vendor_name         text,                 -- VA1.3
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE datacenter_rack (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    datacenter_room_id  uuid        NOT NULL REFERENCES datacenter_room (id),
    name                text        NOT NULL,  -- A02
    role                text,                  -- TRITON, MANTA, NETWORK, CERES
    rack_size           integer,               -- total number of RU
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- Define regional subnets.
CREATE TABLE datacenter_network (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    datacenter_id       uuid        NOT NULL REFERENCES datacenter (id),
    subnet              cidr        NOT NULL,
    name                text        NOT NULL,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- Define per-DC/AZ subnets. May reference a datacenter_network, but
-- not always.
CREATE TABLE datacenter_room_network (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    network_id          uuid        NOT NULL REFERENCES datacenter_network (id),
    datacenter_room_id  uuid        REFERENCES datacenter_room (id),
    subnet              cidr        NOT NULL,
    name                text        NOT NULL,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE hardware_vendor (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    name                text        UNIQUE NOT NULL,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- Define the type of pool to build
CREATE TABLE zpool_profile (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    name                text,       -- mirror, raidz2, customX
    vdev                integer,    -- number of root vdevs
    disk_per            integer,    -- disks per vdev
    spare               integer,
    log                 integer,
    cache               integer,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- Define per-profile zpool attributes. Compression, logbias, recordsize, etc.
CREATE TABLE zpool_attributes (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id          uuid        NOT NULL REFERENCES hardware_product (id),
    name                text,
    value               text,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- joyent hardware makes ("products")
CREATE TABLE hardware_product (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    name                text        UNIQUE NOT NULL, -- Joyent-Compute-Platform-1101
    alias               text        UNIQUE NOT NULL, -- Richmond A
    prefix              text        UNIQUE,          -- RA
    vendor              uuid        NOT NULL REFERENCES hardware_vendor (id),
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- joyent hardware makes specs, used for validation
-- the disk bits here are kind of terrible, but.
-- TODO: hardware_product_profile_disks: Granular disk map to support
-- stranger mixed-disk chassis.
CREATE TABLE hardware_product_profile (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id          uuid        NOT NULL REFERENCES hardware_product (id),
    zpool_id            uuid        NOT NULL REFERENCES zpool_profile (id),
    purpose             text        NOT NULL, -- General Compute
    bios_firmware       text        NOT NULL, -- prtdiag output; Dell Inc. 2.2.5 09/06/2016
    hba_firmware        text,
    cpu_num             integer     NOT NULL,
    cpu_type            text        NOT NULL, -- prtdiag output:
                                              -- Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz
    dimms_num           integer     NOT NULL,
    ram_total           integer     NOT NULL, -- prtconf -m: 262050 (MB)
    nics_num            integer     NOT NULL,
    sata_num            integer,
    sata_size           integer,
    sata_slots          text,                 -- A range of where we expect to find these disks
    sas_num             integer,
    sas_size            integer,
    sas_slots           text,                 -- A range of where we expect to find these disks
    ssd_num             integer,
    ssd_size            integer,
    ssd_slots           text,                 -- A range of where we expect to find these disks
    psu_total           integer,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- denormalized dumping ground for changes we make to systems, like boot order,
-- fan speeds, etc. Can also dump env requirements here, like temp ranges.
CREATE TABLE hardware_profile_settings (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id          uuid        NOT NULL REFERENCES hardware_product_profile (id),
    resource            text        NOT NULL, -- component: bios, ipmi, disk, etc.
    name                text        NOT NULL, -- element to lookup
    value               text        NOT NULL, -- required value
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- The total number of expected systems of a given time, per rack.
-- Used for generating reports.
CREATE TABLE hardware_totals (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    datacenter_rack     uuid        NOT NULL REFERENCES datacenter_rack (id),
    hardware_product    uuid        NOT NULL REFERENCES hardware_product (id),
    total               integer     NOT NULL
);

CREATE TABLE device (
    id                  text        PRIMARY KEY, -- System serial number
    system_uuid         uuid        UNIQUE, -- We get this on the first run from ohai/dmi
    hardware_product    uuid        NOT NULL REFERENCES hardware_product (id),
    boot_phase          text,                 -- memtest, firmware, test, none
    role                text,
    state               text        NOT NULL, -- ONLINE, REBOOTING, UNKNOWN
    health              text        NOT NULL, -- PASS, FAIL, UNKNOWN
    graduated           timestamptz DEFAULT NULL, -- Device has moved to production
    deactivated         timestamptz DEFAULT NULL,
    last_seen           timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE triton (
    id                  text        PRIMARY KEY NOT NULL REFERENCES device (id),
    triton_uuid         uuid        NOT NULL UNIQUE,  -- We pull this from Triton when it's available
                                                      -- Triton sometimes byte-shifts the system UUID,
                                                      -- so we can't assume they are the same.
    setup               boolean     NOT NULL DEFAULT FALSE, -- This is the basic "setup" field in Triton.
    post_setup          boolean     NOT NULL DEFAULT FALSE, -- Post-setup setup.
    state               text        NOT NULL, -- ONLINE, REBOOTING, UNKNOWN
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- The current stage the system is setup at. Post-basic Triton setup, we modify
-- the GZ in various ways.
-- Each stage of post-setup needs to be defined here.
CREATE TABLE triton_post_setup_stage (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    name                text        NOT NULL UNIQUE,
    requires            uuid        NOT NULL REFERENCES triton_post_setup_stage (id),
    description         text,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
);

-- Tracks where in the triton_post_setup_stage process each CN is at.
CREATE TABLE triton_post_setup (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    triton_uuid         uuid        NOT NULL REFERENCES triton(id),
    stage               uuid        NOT NULL REFERENCES triton_post_setup_stage (id),
    status              boolean     NOT NULL DEFAULT FALSE,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- If a stage needs to be re-run, we want to capture all log entries, not just
-- the most recent.
CREATE TABLE triton_post_setup_log (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    stage_id            uuid        NOT NULL REFERENCES triton_post_setup (id),
    log                 text        NOT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp
);

-- denormalized dumping ground for changes we made to systems, like boot order,
-- fan speeds, etc.
CREATE TABLE device_settings (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id           text        NOT NULL REFERENCES device (id),
    resource_id         uuid        NOT NULL REFERENCES hardware_profile_settings (id),
    value               text        NOT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE device_location (
    device_id           text        PRIMARY KEY NOT NULL REFERENCES device (id),
    rack_id             uuid        NOT NULL REFERENCES datacenter_rack (id),
    rack_unit           integer     NOT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- All temps should be in C
CREATE TABLE device_environment (
    device_id           text        PRIMARY KEY NOT NULL REFERENCES device (id),
    cpu0_temp           integer,
    cpu1_temp           integer,
    inlet_temp          integer,
    exhaust_temp        integer,
    psu0_voltage        decimal,
    psu1_voltage        decimal,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE device_specs (
    device_id           text        PRIMARY KEY NOT NULL REFERENCES device (id),
    product_id          uuid        NOT NULL REFERENCES hardware_product_profile (id),
    bios_firmware       text        NOT NULL, -- prtdiag output; Dell Inc. 2.2.5 09/06/2016
    hba_firmware        text,
    cpu_num             integer     NOT NULL,
    cpu_type            text        NOT NULL, -- prtdiag output:
                                              -- Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz
    nics_num            integer     NOT NULL,
    dimms_num           integer     NOT NULL,
    ram_total           integer     NOT NULL -- prtconf -m: 262050 (MB)
);

-- Map DIMMS to the banks in a device. Mark when a DIMM has been replaced.
CREATE TABLE device_memory (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id           text        PRIMARY KEY NOT NULL REFERENCES device (id),
    serial_number       text        NOT NULL, -- May be used in other systems, so not UNIQUE.
    vendor              text        NOT NULL, -- TODO: REF this out
    model               text        NOT NULL,
    bank                text        NOT NULL, -- A04, B03, etc.
    speed               text        NOT NULL,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE device_disk (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id           text        NOT NULL REFERENCES device (id),
    serial_number       text        UNIQUE NOT NULL,
    hba                 integer,
    slot                integer     NOT NULL,
    size                integer     NOT NULL, -- MBytes
    vendor              text,                 -- TODO: REF this out
    model               text,                 -- TODO: REF this out
    firmware            text,                 -- version
    transport           text,                 -- version
    health              text,
    drive_type          text,
    temp                integer,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE device_nic (
    mac                 macaddr     PRIMARY KEY NOT NULL,
    device_id           text        NOT NULL REFERENCES device (id),
    iface_name          text        NOT NULL, -- eth0, ixgbe0
    iface_type          text        NOT NULL,
    iface_vendor        text        NOT NULL,
    iface_driver        text,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- this is a log table, so we can track port changes over time.
CREATE TABLE device_nic_state (
    mac                 macaddr     PRIMARY KEY NOT NULL REFERENCES device_nic (mac),
    state               text,
    speed               text,
    ipaddr              inet,
    mtu                 integer,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- this is a log table, so we can track port changes over time.
CREATE TABLE device_neighbor (
    mac                 macaddr     PRIMARY KEY NOT NULL REFERENCES device_nic (mac),
    raw_text            text,       --- raw command output
    peer_switch         text,       --- from LLDP
    peer_port           text,       --- from LLDP
    want_switch         text,       --- from wiremap spec
    want_port           text,       --- from wiremap spec
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE device_validate_criteria (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id          uuid        REFERENCES hardware_product_profile (id),
    component           text        NOT NULL, -- what we're testing (CPU)
    condition           text        NOT NULL, -- the part of the thing (temp)
    vendor              text,
    model               text,
    string              text,
    min                 integer,
    warn                integer,
    crit                integer
);

-- log which tests a device has passed or failed here.
CREATE TABLE device_validate (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id           uuid,
    device_id           text        NOT NULL REFERENCES device (id),
    component_type      text        NOT NULL, -- type of thing we're testing
    component_name      text        NOT NULL, -- actual thingwe're testing
    component_id        uuid,                 -- if we can reference a component we should fill this out.
    criteria_id         uuid        REFERENCES device_validate_criteria (id),
    metric              integer,
    log                 text,
    status              boolean     NOT NULL, -- true, false, unknown
    created             timestamptz NOT NULL DEFAULT current_timestamp
);

-- this is a log table for PSU info, fan speed changes, chassis/disk temp
-- changes, etc. Populated on discovery and when things change.
CREATE TABLE device_log (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id           text       NOT NULL REFERENCES device (id),
    component_type      text        NOT NULL, -- PSU, chassis, disk, fan, etc.
    component_id        uuid,                 -- if we can reference a component we should fill this out.
    log                 text        NOT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp
);

-- Admin notes.
CREATE TABLE device_notes (
    id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id           text        NOT NULL REFERENCES device (id),
    text                text        NOT NULL,
    author              text        NOT NULL,
    ticket_id           text,       -- Field for JIRA tickets or whatever.
    created             timestamptz NOT NULL DEFAULT current_timestamp
);

-----------------------------------------------------------------------------
-- Indexes
-----------------------------------------------------------------------------

-- CREATE INDEX user_to_device     ON device               (user_id);
