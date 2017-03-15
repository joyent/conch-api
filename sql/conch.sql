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

CREATE TABLE datacenter (
    id                  uuid        PRIMARY KEY,
    vendor              text        NOT NULL, -- Raging Wire
    vendor_name         text,                 -- VA1
    region              text        NOT NULL, -- us-east1
    location            text        NOT NULL, -- Ashburn, VA, USA
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE datacenter_room (
    id                  uuid        PRIMARY KEY,
    datacenter          uuid        NOT NULL REFERENCES datacenter (id),
    az                  text        NOT NULL, -- us-east-1b
    alias               text,                 -- AZ1
    vendor_name         text,                 -- VA1.3
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE datacenter_rack (
    id                  uuid        PRIMARY KEY,
    datacenter_id       uuid        NOT NULL REFERENCES datacenter (id),
    name                text        NOT NULL,  -- A02
    rack_size           integer,               -- total number of RU
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE hardware_vendor (
    id                  uuid        PRIMARY KEY,
    name                text        UNIQUE NOT NULL,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- joyent hardware makes ("products")
CREATE TABLE hardware_product (
    id                  uuid        PRIMARY KEY,
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
    id                  uuid        PRIMARY KEY,
    product_id          uuid        NOT NULL REFERENCES hardware_product (id),
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
    sas_num             integer,
    sas_size            integer,
    ssd_num             integer,
    ssd_size            integer,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- denormalized dumping ground for changes we make to systems, like boot order,
-- fan speeds, etc. Can also dump env requirements here, like temp ranges.
CREATE TABLE hardware_profile_settings (
    id                  uuid        PRIMARY KEY,
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
    id                  uuid        PRIMARY KEY,
    datacenter_rack     uuid        NOT NULL REFERENCES datacenter_rack (id),
    hardware_product    uuid        NOT NULL REFERENCES hardware_product (id),
    total               integer     NOT NULL
);

CREATE TABLE device (
    id                  uuid        PRIMARY KEY,
    serial_number       text        UNIQUE NOT NULL,
    hardware_product    uuid        NOT NULL REFERENCES hardware_product (id),
    state               text        NOT NULL, -- TODO: define ENUMs
    health              text        NOT NULL, -- TODO: define ENUMs
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- denormalized dumping ground for changes we made to systems, like boot order,
-- fan speeds, etc.
CREATE TABLE device_settings (
    id                  uuid        PRIMARY KEY,
    device_id           uuid        NOT NULL REFERENCES device (id),
    resource_id         uuid        NOT NULL REFERENCES hardware_profile_settings (id),
    value               text        NOT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE device_location (
    device_id           uuid        PRIMARY KEY NOT NULL REFERENCES device (id),
    location            uuid        NOT NULL REFERENCES datacenter_rack (id),
    rack_unit           integer     NOT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE device_specs (
    device_id           uuid        PRIMARY KEY NOT NULL REFERENCES device (id),
    product_id          uuid        NOT NULL REFERENCES hardware_product_profile (id),
    bios_firmware       text        NOT NULL, -- prtdiag output; Dell Inc. 2.2.5 09/06/2016
    hba_firmware        text,
    cpu_num             integer     NOT NULL,
    cpu_type            text        NOT NULL, -- prtdiag output:
                                              -- Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz
    dimms_num           integer     NOT NULL,
    ram_total           integer     NOT NULL -- prtconf -m: 262050 (MB)
);

CREATE TABLE device_disk (
    id                  uuid        PRIMARY KEY,
    device_id           uuid        NOT NULL REFERENCES device (id),
    hba                 integer,
    slot                integer     NOT NULL,
    size                integer     NOT NULL, -- MBytes
    vendor              text,                 -- TODO: REF this out
    firmware            text,                 -- version
    serial_number       text,
    health              text,
    deactivated         timestamptz DEFAULT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE TABLE device_nic (
    mac                 macaddr     PRIMARY KEY NOT NULL,
    device_id           uuid        NOT NULL REFERENCES device (id),
    iface_name          text        NOT NULL, -- eth0, ixgbe0
    iface_type          text        NOT NULL,
    iface_vendor        text        NOT NULL,
    iface_driver        text,
    created             timestamptz NOT NULL DEFAULT current_timestamp,
    updated             timestamptz NOT NULL DEFAULT current_timestamp
);

-- this is a log table, so we can track port changes over time.
CREATE TABLE device_nic_state (
    id                  uuid        PRIMARY KEY,
    nic_id              macaddr     NOT NULL REFERENCES device_nic (mac),
    state               text,
    speed               text,
    ipaddr              inet,
    mtu                 integer,
    created             timestamptz NOT NULL DEFAULT current_timestamp
);

-- this is a log table, so we can track port changes over time.
CREATE TABLE device_neighbor (
    id                  uuid        PRIMARY KEY,
    nic_id              macaddr     NOT NULL REFERENCES device_nic (mac),
    raw_text            text,       --- raw command output
    peer_switch         text,
    peer_port           text,
    created             timestamptz NOT NULL DEFAULT current_timestamp
);

-- this is a log table for PSU info, fan speed changes, chassis/disk temp
-- changes, etc. Populated on discovery and when things change.
CREATE TABLE device_log (
    id                  uuid        PRIMARY KEY,
    device_id           uuid        NOT NULL REFERENCES device (id),
    component_type      text        NOT NULL, -- PSU, chassis, disk, fan, etc.
    component_id        uuid,                 -- if we can reference a component we should fill this out.
    log                 text        NOT NULL,
    created             timestamptz NOT NULL DEFAULT current_timestamp
);

-- Admin notes.
CREATE TABLE device_notes (
    id                  uuid        PRIMARY KEY,
    device_id           uuid        NOT NULL REFERENCES device (id),
    text                text        NOT NULL,
    author              text        NOT NULL,
    ticket_id           text,       -- Field for JIRA tickets or whatever.
    created             timestamptz NOT NULL DEFAULT current_timestamp
);

-----------------------------------------------------------------------------
-- Indexes
-----------------------------------------------------------------------------

-- CREATE INDEX user_to_device     ON device               (user_id);
