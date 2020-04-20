--
-- PostgreSQL database dump
--

-- Dumped from database version 10.14
-- Dumped by pg_dump version 10.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: completed_status_enum; Type: TYPE; Schema: public; Owner: conch
--

CREATE TYPE public.completed_status_enum AS ENUM (
    'failure',
    'success'
);


ALTER TYPE public.completed_status_enum OWNER TO conch;

--
-- Name: device_health_enum; Type: TYPE; Schema: public; Owner: conch
--

CREATE TYPE public.device_health_enum AS ENUM (
    'error',
    'fail',
    'unknown',
    'pass'
);


ALTER TYPE public.device_health_enum OWNER TO conch;

--
-- Name: device_phase_enum; Type: TYPE; Schema: public; Owner: conch
--

CREATE TYPE public.device_phase_enum AS ENUM (
    'integration',
    'installation',
    'production',
    'diagnostics',
    'decommissioned'
);


ALTER TYPE public.device_phase_enum OWNER TO conch;

--
-- Name: role_enum; Type: TYPE; Schema: public; Owner: conch
--

CREATE TYPE public.role_enum AS ENUM (
    'ro',
    'rw',
    'admin'
);


ALTER TYPE public.role_enum OWNER TO conch;

--
-- Name: validation_status_enum; Type: TYPE; Schema: public; Owner: conch
--

CREATE TYPE public.validation_status_enum AS ENUM (
    'error',
    'fail',
    'pass'
);


ALTER TYPE public.validation_status_enum OWNER TO conch;

--
-- Name: array_cat_distinct(anyarray, anyarray); Type: FUNCTION; Schema: public; Owner: conch
--

CREATE FUNCTION public.array_cat_distinct(anyarray, anyarray) RETURNS anyarray
    LANGUAGE sql IMMUTABLE
    AS $_$
      select array(select distinct unnest(array_cat($1, $2)) order by 1);
    $_$;


ALTER FUNCTION public.array_cat_distinct(anyarray, anyarray) OWNER TO conch;

--
-- Name: array_subtract(anyarray, anyarray); Type: FUNCTION; Schema: public; Owner: conch
--

CREATE FUNCTION public.array_subtract(anyarray, anyarray) RETURNS anyarray
    LANGUAGE sql IMMUTABLE
    AS $_$
      select array(select unnest($1) except select unnest($2) order by 1);
    $_$;


ALTER FUNCTION public.array_subtract(anyarray, anyarray) OWNER TO conch;

--
-- Name: run_migration(integer, text); Type: FUNCTION; Schema: public; Owner: conch
--

CREATE FUNCTION public.run_migration(integer, text) RETURNS void
    LANGUAGE plpgsql
    AS $_$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM migration WHERE id = $1) THEN
        EXECUTE $2;
        INSERT INTO migration (id) VALUES ($1);
        RAISE LOG 'Migration % completed.', $1;
    END IF;
END;
$_$;


ALTER FUNCTION public.run_migration(integer, text) OWNER TO conch;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: build; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.build (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created timestamp with time zone DEFAULT now() NOT NULL,
    started timestamp with time zone,
    completed timestamp with time zone,
    completed_user_id uuid,
    links text[] DEFAULT '{}'::text[] NOT NULL,
    completed_status public.completed_status_enum,
    CONSTRAINT build_completed_iff_started_check CHECK (((completed IS NULL) OR (started IS NOT NULL))),
    CONSTRAINT build_completed_xnor_completed_status_check CHECK ((((completed IS NULL) AND (completed_status IS NULL)) OR ((completed IS NOT NULL) AND (completed_status IS NOT NULL)))),
    CONSTRAINT build_completed_xnor_completed_user_id_check CHECK ((((completed IS NULL) AND (completed_user_id IS NULL)) OR ((completed IS NOT NULL) AND (completed_user_id IS NOT NULL))))
);


ALTER TABLE public.build OWNER TO conch;

--
-- Name: datacenter; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.datacenter (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    vendor text NOT NULL,
    vendor_name text,
    region text NOT NULL,
    location text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.datacenter OWNER TO conch;

--
-- Name: datacenter_room; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.datacenter_room (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    datacenter_id uuid NOT NULL,
    az text NOT NULL,
    alias text NOT NULL,
    vendor_name text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.datacenter_room OWNER TO conch;

--
-- Name: device; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device (
    serial_number text NOT NULL,
    system_uuid uuid,
    hardware_product_id uuid NOT NULL,
    health public.device_health_enum NOT NULL,
    last_seen timestamp with time zone,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    uptime_since timestamp with time zone,
    validated timestamp with time zone,
    asset_tag text,
    hostname text,
    phase public.device_phase_enum DEFAULT 'integration'::public.device_phase_enum NOT NULL,
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    links text[] DEFAULT '{}'::text[] NOT NULL,
    build_id uuid
);


ALTER TABLE public.device OWNER TO conch;

--
-- Name: device_disk; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_disk (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    serial_number text NOT NULL,
    slot integer,
    size integer,
    vendor text,
    model text,
    firmware text,
    transport text,
    health text,
    drive_type text,
    deactivated timestamp with time zone,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    enclosure integer,
    hba integer,
    device_id uuid NOT NULL
);


ALTER TABLE public.device_disk OWNER TO conch;

--
-- Name: device_location; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_location (
    rack_id uuid NOT NULL,
    rack_unit_start integer NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    device_id uuid NOT NULL,
    CONSTRAINT device_location_rack_unit_start_check CHECK ((rack_unit_start > 0))
);


ALTER TABLE public.device_location OWNER TO conch;

--
-- Name: device_neighbor; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_neighbor (
    mac macaddr NOT NULL,
    raw_text text,
    peer_switch text,
    peer_port text,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    peer_mac macaddr
);


ALTER TABLE public.device_neighbor OWNER TO conch;

--
-- Name: device_nic; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_nic (
    mac macaddr NOT NULL,
    iface_name text NOT NULL,
    iface_type text NOT NULL,
    iface_vendor text NOT NULL,
    deactivated timestamp with time zone,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    state text,
    ipaddr inet,
    mtu integer,
    device_id uuid NOT NULL
);


ALTER TABLE public.device_nic OWNER TO conch;

--
-- Name: device_relay_connection; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_relay_connection (
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL,
    relay_id uuid NOT NULL,
    device_id uuid NOT NULL
);


ALTER TABLE public.device_relay_connection OWNER TO conch;

--
-- Name: device_report; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_report (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    report jsonb NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    retain boolean,
    device_id uuid NOT NULL
);


ALTER TABLE public.device_report OWNER TO conch;

--
-- Name: device_setting; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_setting (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    value text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    deactivated timestamp with time zone,
    name text NOT NULL,
    device_id uuid NOT NULL
);


ALTER TABLE public.device_setting OWNER TO conch;

--
-- Name: hardware_product; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.hardware_product (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    alias text NOT NULL,
    prefix text,
    hardware_vendor_id uuid NOT NULL,
    deactivated timestamp with time zone,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    specification jsonb DEFAULT '{}'::jsonb NOT NULL,
    sku text NOT NULL,
    generation_name text,
    legacy_product_name text,
    rack_unit_size integer NOT NULL,
    validation_plan_id uuid NOT NULL,
    purpose text NOT NULL,
    bios_firmware text NOT NULL,
    hba_firmware text,
    cpu_num integer DEFAULT 0 NOT NULL,
    cpu_type text NOT NULL,
    dimms_num integer DEFAULT 0 NOT NULL,
    ram_total integer DEFAULT 0 NOT NULL,
    nics_num integer DEFAULT 0 NOT NULL,
    sata_hdd_num integer DEFAULT 0 NOT NULL,
    sata_hdd_size integer,
    sata_hdd_slots text,
    sas_hdd_num integer DEFAULT 0 NOT NULL,
    sas_hdd_size integer,
    sas_hdd_slots text,
    sata_ssd_num integer DEFAULT 0 NOT NULL,
    sata_ssd_size integer,
    sata_ssd_slots text,
    psu_total integer DEFAULT 0 NOT NULL,
    usb_num integer DEFAULT 0 NOT NULL,
    sas_ssd_num integer DEFAULT 0 NOT NULL,
    sas_ssd_size integer,
    sas_ssd_slots text,
    nvme_ssd_num integer DEFAULT 0 NOT NULL,
    nvme_ssd_size integer,
    nvme_ssd_slots text,
    raid_lun_num integer DEFAULT 0 NOT NULL,
    CONSTRAINT hardware_product_rack_unit_size_check CHECK ((rack_unit_size > 0))
);


ALTER TABLE public.hardware_product OWNER TO conch;

--
-- Name: hardware_vendor; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.hardware_vendor (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    deactivated timestamp with time zone,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.hardware_vendor OWNER TO conch;

--
-- Name: json_schema; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.json_schema (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    type text NOT NULL,
    name text NOT NULL,
    version integer NOT NULL,
    body jsonb NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    created_user_id uuid NOT NULL,
    deactivated timestamp with time zone,
    CONSTRAINT json_schema_version_check CHECK ((version > 0))
);


ALTER TABLE public.json_schema OWNER TO conch;

--
-- Name: legacy_validation_result; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.legacy_validation_result (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    validation_id uuid NOT NULL,
    message text NOT NULL,
    hint text,
    status public.validation_status_enum NOT NULL,
    category text NOT NULL,
    component text,
    created timestamp with time zone DEFAULT now() NOT NULL,
    device_id uuid NOT NULL
);


ALTER TABLE public.legacy_validation_result OWNER TO conch;

--
-- Name: legacy_validation_state_member; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.legacy_validation_state_member (
    validation_state_id uuid NOT NULL,
    legacy_validation_result_id uuid NOT NULL,
    result_order integer NOT NULL,
    CONSTRAINT l_validation_state_member_result_order_check CHECK ((result_order >= 0))
);


ALTER TABLE public.legacy_validation_state_member OWNER TO conch;

--
-- Name: migration; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.migration (
    id integer NOT NULL,
    created timestamp with time zone DEFAULT now(),
    CONSTRAINT migration_id_check CHECK ((id >= 0))
);


ALTER TABLE public.migration OWNER TO conch;

--
-- Name: organization; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.organization (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created timestamp with time zone DEFAULT now() NOT NULL,
    deactivated timestamp with time zone
);


ALTER TABLE public.organization OWNER TO conch;

--
-- Name: organization_build_role; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.organization_build_role (
    organization_id uuid NOT NULL,
    build_id uuid NOT NULL,
    role public.role_enum DEFAULT 'ro'::public.role_enum NOT NULL
);


ALTER TABLE public.organization_build_role OWNER TO conch;

--
-- Name: rack; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.rack (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    datacenter_room_id uuid NOT NULL,
    name text NOT NULL,
    rack_role_id uuid NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    serial_number text,
    asset_tag text,
    phase public.device_phase_enum DEFAULT 'integration'::public.device_phase_enum NOT NULL,
    build_id uuid,
    links text[] DEFAULT '{}'::text[] NOT NULL
);


ALTER TABLE public.rack OWNER TO conch;

--
-- Name: rack_layout; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.rack_layout (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    rack_id uuid NOT NULL,
    hardware_product_id uuid NOT NULL,
    rack_unit_start integer NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT rack_layout_rack_unit_start_check CHECK ((rack_unit_start > 0))
);


ALTER TABLE public.rack_layout OWNER TO conch;

--
-- Name: rack_role; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.rack_role (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    rack_size integer NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT rack_role_rack_size_check CHECK ((rack_size > 0))
);


ALTER TABLE public.rack_role OWNER TO conch;

--
-- Name: relay; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.relay (
    serial_number text NOT NULL,
    name text,
    version text,
    ipaddr inet,
    ssh_port integer,
    deactivated timestamp with time zone,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid NOT NULL,
    CONSTRAINT relay_ssh_port_check CHECK ((ssh_port >= 0))
);


ALTER TABLE public.relay OWNER TO conch;

--
-- Name: user_account; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.user_account (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    password text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    last_login timestamp with time zone,
    email text NOT NULL,
    deactivated timestamp with time zone,
    refuse_session_auth boolean DEFAULT false NOT NULL,
    force_password_change boolean DEFAULT false NOT NULL,
    is_admin boolean DEFAULT false NOT NULL,
    last_seen timestamp with time zone
);


ALTER TABLE public.user_account OWNER TO conch;

--
-- Name: user_build_role; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.user_build_role (
    user_id uuid NOT NULL,
    build_id uuid NOT NULL,
    role public.role_enum DEFAULT 'ro'::public.role_enum NOT NULL
);


ALTER TABLE public.user_build_role OWNER TO conch;

--
-- Name: user_organization_role; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.user_organization_role (
    user_id uuid NOT NULL,
    organization_id uuid NOT NULL,
    role public.role_enum DEFAULT 'ro'::public.role_enum NOT NULL
);


ALTER TABLE public.user_organization_role OWNER TO conch;

--
-- Name: user_session_token; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.user_session_token (
    user_id uuid NOT NULL,
    expires timestamp with time zone NOT NULL,
    name text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    last_used timestamp with time zone,
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    last_ipaddr inet
);


ALTER TABLE public.user_session_token OWNER TO conch;

--
-- Name: user_setting; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.user_setting (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    name text NOT NULL,
    value text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    deactivated timestamp with time zone
);


ALTER TABLE public.user_setting OWNER TO conch;

--
-- Name: validation; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.validation (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    version integer NOT NULL,
    description text NOT NULL,
    module text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    deactivated timestamp with time zone,
    CONSTRAINT validation_version_check CHECK ((version > 0))
);


ALTER TABLE public.validation OWNER TO conch;

--
-- Name: validation_plan; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.validation_plan (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    deactivated timestamp with time zone
);


ALTER TABLE public.validation_plan OWNER TO conch;

--
-- Name: validation_plan_member; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.validation_plan_member (
    validation_id uuid NOT NULL,
    validation_plan_id uuid NOT NULL
);


ALTER TABLE public.validation_plan_member OWNER TO conch;

--
-- Name: validation_state; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.validation_state (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    status public.validation_status_enum NOT NULL,
    device_report_id uuid NOT NULL,
    device_id uuid NOT NULL,
    hardware_product_id uuid NOT NULL
);


ALTER TABLE public.validation_state OWNER TO conch;

--
-- Name: build build_name_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.build
    ADD CONSTRAINT build_name_key UNIQUE (name);


--
-- Name: build build_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.build
    ADD CONSTRAINT build_pkey PRIMARY KEY (id);


--
-- Name: datacenter datacenter_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.datacenter
    ADD CONSTRAINT datacenter_pkey PRIMARY KEY (id);


--
-- Name: datacenter_room datacenter_room_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.datacenter_room
    ADD CONSTRAINT datacenter_room_pkey PRIMARY KEY (id);


--
-- Name: datacenter_room datacenter_room_vendor_name_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.datacenter_room
    ADD CONSTRAINT datacenter_room_vendor_name_key UNIQUE (vendor_name);


--
-- Name: datacenter datacenter_vendor_region_location_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.datacenter
    ADD CONSTRAINT datacenter_vendor_region_location_key UNIQUE (vendor, region, location);


--
-- Name: device_disk device_disk_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_disk
    ADD CONSTRAINT device_disk_pkey PRIMARY KEY (id);


--
-- Name: device_disk device_disk_serial_number_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_disk
    ADD CONSTRAINT device_disk_serial_number_key UNIQUE (serial_number);


--
-- Name: device_location device_location_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_location
    ADD CONSTRAINT device_location_pkey PRIMARY KEY (device_id);


--
-- Name: device_location device_location_rack_id_rack_unit_start_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_location
    ADD CONSTRAINT device_location_rack_id_rack_unit_start_key UNIQUE (rack_id, rack_unit_start) DEFERRABLE;


--
-- Name: device_neighbor device_neighbor_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_neighbor
    ADD CONSTRAINT device_neighbor_pkey PRIMARY KEY (mac);


--
-- Name: device_nic device_nic_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_nic
    ADD CONSTRAINT device_nic_pkey PRIMARY KEY (mac);


--
-- Name: device device_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_pkey PRIMARY KEY (id);


--
-- Name: device_relay_connection device_relay_connection_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_relay_connection
    ADD CONSTRAINT device_relay_connection_pkey PRIMARY KEY (device_id, relay_id);


--
-- Name: device_report device_report_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_report
    ADD CONSTRAINT device_report_pkey PRIMARY KEY (id);


--
-- Name: device device_serial_number_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_serial_number_key UNIQUE (serial_number) DEFERRABLE;


--
-- Name: device_setting device_setting_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_setting
    ADD CONSTRAINT device_setting_pkey PRIMARY KEY (id);


--
-- Name: device device_system_uuid_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_system_uuid_key UNIQUE (system_uuid);


--
-- Name: hardware_product hardware_product_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.hardware_product
    ADD CONSTRAINT hardware_product_pkey PRIMARY KEY (id);


--
-- Name: hardware_vendor hardware_vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.hardware_vendor
    ADD CONSTRAINT hardware_vendor_pkey PRIMARY KEY (id);


--
-- Name: json_schema json_schema_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.json_schema
    ADD CONSTRAINT json_schema_pkey PRIMARY KEY (id);


--
-- Name: json_schema json_schema_type_name_version_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.json_schema
    ADD CONSTRAINT json_schema_type_name_version_key UNIQUE (type, name, version);


--
-- Name: legacy_validation_result l_validation_result_all_columns_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.legacy_validation_result
    ADD CONSTRAINT l_validation_result_all_columns_key UNIQUE (device_id, validation_id, message, hint, status, category, component);


--
-- Name: legacy_validation_result l_validation_result_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.legacy_validation_result
    ADD CONSTRAINT l_validation_result_pkey PRIMARY KEY (id);


--
-- Name: legacy_validation_state_member l_validation_state_member_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.legacy_validation_state_member
    ADD CONSTRAINT l_validation_state_member_pkey PRIMARY KEY (validation_state_id, legacy_validation_result_id);


--
-- Name: legacy_validation_state_member l_validation_state_member_validation_state_id_result_order_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.legacy_validation_state_member
    ADD CONSTRAINT l_validation_state_member_validation_state_id_result_order_key UNIQUE (validation_state_id, result_order);


--
-- Name: migration migration_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.migration
    ADD CONSTRAINT migration_pkey PRIMARY KEY (id);


--
-- Name: organization_build_role organization_build_role_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.organization_build_role
    ADD CONSTRAINT organization_build_role_pkey PRIMARY KEY (organization_id, build_id);


--
-- Name: organization organization_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: rack rack_datacenter_room_id_name_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack
    ADD CONSTRAINT rack_datacenter_room_id_name_key UNIQUE (datacenter_room_id, name);


--
-- Name: rack_layout rack_layout_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack_layout
    ADD CONSTRAINT rack_layout_pkey PRIMARY KEY (id);


--
-- Name: rack_layout rack_layout_rack_id_rack_unit_start_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack_layout
    ADD CONSTRAINT rack_layout_rack_id_rack_unit_start_key UNIQUE (rack_id, rack_unit_start);


--
-- Name: rack rack_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack
    ADD CONSTRAINT rack_pkey PRIMARY KEY (id);


--
-- Name: rack_role rack_role_name_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack_role
    ADD CONSTRAINT rack_role_name_key UNIQUE (name);


--
-- Name: rack_role rack_role_name_rack_size_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack_role
    ADD CONSTRAINT rack_role_name_rack_size_key UNIQUE (name, rack_size);


--
-- Name: rack_role rack_role_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack_role
    ADD CONSTRAINT rack_role_pkey PRIMARY KEY (id);


--
-- Name: relay relay_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.relay
    ADD CONSTRAINT relay_pkey PRIMARY KEY (id);


--
-- Name: relay relay_serial_number_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.relay
    ADD CONSTRAINT relay_serial_number_key UNIQUE (serial_number);


--
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (id);


--
-- Name: user_build_role user_build_role_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_build_role
    ADD CONSTRAINT user_build_role_pkey PRIMARY KEY (user_id, build_id);


--
-- Name: user_organization_role user_organization_role_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_organization_role
    ADD CONSTRAINT user_organization_role_pkey PRIMARY KEY (user_id, organization_id);


--
-- Name: user_session_token user_session_token_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_session_token
    ADD CONSTRAINT user_session_token_pkey PRIMARY KEY (id);


--
-- Name: user_setting user_setting_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_setting
    ADD CONSTRAINT user_setting_pkey PRIMARY KEY (id);


--
-- Name: validation validation_name_version_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation
    ADD CONSTRAINT validation_name_version_key UNIQUE (name, version);


--
-- Name: validation validation_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation
    ADD CONSTRAINT validation_pkey PRIMARY KEY (id);


--
-- Name: validation_plan_member validation_plan_member_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_plan_member
    ADD CONSTRAINT validation_plan_member_pkey PRIMARY KEY (validation_id, validation_plan_id);


--
-- Name: validation_plan validation_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_plan
    ADD CONSTRAINT validation_plan_pkey PRIMARY KEY (id);


--
-- Name: validation_state validation_state_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_state
    ADD CONSTRAINT validation_state_pkey PRIMARY KEY (id);


--
-- Name: build_links_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX build_links_idx ON public.build USING gin (links);


--
-- Name: datacenter_room_alias_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX datacenter_room_alias_key ON public.datacenter_room USING btree (alias);


--
-- Name: datacenter_room_datacenter_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX datacenter_room_datacenter_id_idx ON public.datacenter_room USING btree (datacenter_id);


--
-- Name: device_build_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_build_id_idx ON public.device USING btree (build_id);


--
-- Name: device_disk_device_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_disk_device_id_idx ON public.device_disk USING btree (device_id);


--
-- Name: device_hardware_product_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_hardware_product_id_idx ON public.device USING btree (hardware_product_id);


--
-- Name: device_hostname_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_hostname_idx ON public.device USING btree (hostname);


--
-- Name: device_links_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_links_idx ON public.device USING gin (links);


--
-- Name: device_location_rack_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_location_rack_id_idx ON public.device_location USING btree (rack_id);


--
-- Name: device_nic_device_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_nic_device_id_idx ON public.device_nic USING btree (device_id);


--
-- Name: device_nic_device_id_iface_name_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX device_nic_device_id_iface_name_key ON public.device_nic USING btree (device_id, iface_name) WHERE (deactivated IS NULL);


--
-- Name: device_nic_iface_name_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_nic_iface_name_idx ON public.device_nic USING btree (iface_name);


--
-- Name: device_nic_ipaddr_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_nic_ipaddr_idx ON public.device_nic USING btree (ipaddr);


--
-- Name: device_relay_connection_relay_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_relay_connection_relay_id_idx ON public.device_relay_connection USING btree (relay_id);


--
-- Name: device_report_created_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_report_created_idx ON public.device_report USING btree (created);


--
-- Name: device_report_device_id_created_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_report_device_id_created_idx ON public.device_report USING btree (device_id, created DESC);


--
-- Name: device_setting_device_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_setting_device_id_idx ON public.device_setting USING btree (device_id);


--
-- Name: device_setting_device_id_name_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX device_setting_device_id_name_idx ON public.device_setting USING btree (device_id, name) WHERE (deactivated IS NULL);


--
-- Name: hardware_product_alias_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX hardware_product_alias_key ON public.hardware_product USING btree (alias) WHERE (deactivated IS NULL);


--
-- Name: hardware_product_hardware_vendor_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX hardware_product_hardware_vendor_id_idx ON public.hardware_product USING btree (hardware_vendor_id);


--
-- Name: hardware_product_name_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX hardware_product_name_key ON public.hardware_product USING btree (name) WHERE (deactivated IS NULL);


--
-- Name: hardware_product_sku_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX hardware_product_sku_key ON public.hardware_product USING btree (sku) WHERE (deactivated IS NULL);


--
-- Name: hardware_vendor_name_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX hardware_vendor_name_key ON public.hardware_vendor USING btree (name) WHERE (deactivated IS NULL);


--
-- Name: json_schema_type_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX json_schema_type_idx ON public.json_schema USING btree (type) WHERE (deactivated IS NULL);


--
-- Name: json_schema_type_name_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX json_schema_type_name_idx ON public.json_schema USING btree (type, name) WHERE (deactivated IS NULL);


--
-- Name: l_validation_result_validation_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX l_validation_result_validation_id_idx ON public.legacy_validation_result USING btree (validation_id);


--
-- Name: l_validation_state_member_legacy_validation_result_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX l_validation_state_member_legacy_validation_result_id_idx ON public.legacy_validation_state_member USING btree (legacy_validation_result_id);


--
-- Name: organization_build_role_build_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX organization_build_role_build_id_idx ON public.organization_build_role USING btree (build_id);


--
-- Name: organization_name_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX organization_name_key ON public.organization USING btree (name) WHERE (deactivated IS NULL);


--
-- Name: rack_build_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX rack_build_id_idx ON public.rack USING btree (build_id);


--
-- Name: rack_datacenter_room_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX rack_datacenter_room_id_idx ON public.rack USING btree (datacenter_room_id);


--
-- Name: rack_layout_hardware_product_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX rack_layout_hardware_product_id_idx ON public.rack_layout USING btree (hardware_product_id);


--
-- Name: rack_layout_rack_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX rack_layout_rack_id_idx ON public.rack_layout USING btree (rack_id);


--
-- Name: rack_links_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX rack_links_idx ON public.rack USING gin (links);


--
-- Name: rack_rack_role_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX rack_rack_role_id_idx ON public.rack USING btree (rack_role_id);


--
-- Name: relay_user_id; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX relay_user_id ON public.relay USING btree (user_id);


--
-- Name: user_account_email_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX user_account_email_key ON public.user_account USING btree (lower(email)) WHERE (deactivated IS NULL);


--
-- Name: user_account_name_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX user_account_name_key ON public.user_account USING btree (name) WHERE (deactivated IS NULL);


--
-- Name: user_build_role_build_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_build_role_build_id_idx ON public.user_build_role USING btree (build_id);


--
-- Name: user_organization_role_organization_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_organization_role_organization_id_idx ON public.user_organization_role USING btree (organization_id);


--
-- Name: user_session_token_expires_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_session_token_expires_idx ON public.user_session_token USING btree (expires);


--
-- Name: user_session_token_user_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_session_token_user_id_idx ON public.user_session_token USING btree (user_id);


--
-- Name: user_session_token_user_id_name_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX user_session_token_user_id_name_key ON public.user_session_token USING btree (user_id, name);


--
-- Name: user_setting_user_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_setting_user_id_idx ON public.user_setting USING btree (user_id);


--
-- Name: user_setting_user_id_name_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX user_setting_user_id_name_idx ON public.user_setting USING btree (user_id, name) WHERE (deactivated IS NULL);


--
-- Name: validation_module_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX validation_module_idx ON public.validation USING btree (module) WHERE (deactivated IS NULL);


--
-- Name: validation_plan_member_validation_plan_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_plan_member_validation_plan_id_idx ON public.validation_plan_member USING btree (validation_plan_id);


--
-- Name: validation_plan_name_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX validation_plan_name_idx ON public.validation_plan USING btree (name) WHERE (deactivated IS NULL);


--
-- Name: validation_state_created_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_created_idx ON public.validation_state USING btree (created);


--
-- Name: validation_state_device_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_device_id_idx ON public.validation_state USING btree (device_id);


--
-- Name: validation_state_device_report_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_device_report_id_idx ON public.validation_state USING btree (device_report_id);


--
-- Name: validation_state_hardware_product_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_hardware_product_id_idx ON public.validation_state USING btree (hardware_product_id);


--
-- Name: build build_completed_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.build
    ADD CONSTRAINT build_completed_user_id_fkey FOREIGN KEY (completed_user_id) REFERENCES public.user_account(id);


--
-- Name: datacenter_room datacenter_room_datacenter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.datacenter_room
    ADD CONSTRAINT datacenter_room_datacenter_fkey FOREIGN KEY (datacenter_id) REFERENCES public.datacenter(id);


--
-- Name: device device_build_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_build_id_fkey FOREIGN KEY (build_id) REFERENCES public.build(id);


--
-- Name: device_disk device_disk_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_disk
    ADD CONSTRAINT device_disk_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device(id);


--
-- Name: device device_hardware_product_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_hardware_product_fkey FOREIGN KEY (hardware_product_id) REFERENCES public.hardware_product(id);


--
-- Name: device_location device_location_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_location
    ADD CONSTRAINT device_location_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device(id);


--
-- Name: device_location device_location_rack_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_location
    ADD CONSTRAINT device_location_rack_id_fkey FOREIGN KEY (rack_id) REFERENCES public.rack(id);


--
-- Name: device_neighbor device_neighbor_mac_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_neighbor
    ADD CONSTRAINT device_neighbor_mac_fkey FOREIGN KEY (mac) REFERENCES public.device_nic(mac);


--
-- Name: device_nic device_nic_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_nic
    ADD CONSTRAINT device_nic_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device(id);


--
-- Name: device_relay_connection device_relay_connection_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_relay_connection
    ADD CONSTRAINT device_relay_connection_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device(id);


--
-- Name: device_relay_connection device_relay_connection_relay_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_relay_connection
    ADD CONSTRAINT device_relay_connection_relay_id_fkey FOREIGN KEY (relay_id) REFERENCES public.relay(id);


--
-- Name: device_report device_report_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_report
    ADD CONSTRAINT device_report_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device(id);


--
-- Name: device_setting device_setting_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_setting
    ADD CONSTRAINT device_setting_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device(id);


--
-- Name: hardware_product hardware_product_validation_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.hardware_product
    ADD CONSTRAINT hardware_product_validation_plan_id_fkey FOREIGN KEY (validation_plan_id) REFERENCES public.validation_plan(id);


--
-- Name: hardware_product hardware_product_vendor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.hardware_product
    ADD CONSTRAINT hardware_product_vendor_fkey FOREIGN KEY (hardware_vendor_id) REFERENCES public.hardware_vendor(id);


--
-- Name: json_schema json_schema_created_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.json_schema
    ADD CONSTRAINT json_schema_created_user_id_fkey FOREIGN KEY (created_user_id) REFERENCES public.user_account(id);


--
-- Name: legacy_validation_result l_validation_result_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.legacy_validation_result
    ADD CONSTRAINT l_validation_result_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device(id);


--
-- Name: legacy_validation_result l_validation_result_validation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.legacy_validation_result
    ADD CONSTRAINT l_validation_result_validation_id_fkey FOREIGN KEY (validation_id) REFERENCES public.validation(id);


--
-- Name: legacy_validation_state_member l_validation_state_member_legacy_validation_result_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.legacy_validation_state_member
    ADD CONSTRAINT l_validation_state_member_legacy_validation_result_id_fkey FOREIGN KEY (legacy_validation_result_id) REFERENCES public.legacy_validation_result(id) ON DELETE CASCADE;


--
-- Name: legacy_validation_state_member l_validation_state_member_validation_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.legacy_validation_state_member
    ADD CONSTRAINT l_validation_state_member_validation_state_id_fkey FOREIGN KEY (validation_state_id) REFERENCES public.validation_state(id) ON DELETE CASCADE;


--
-- Name: organization_build_role organization_build_role_build_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.organization_build_role
    ADD CONSTRAINT organization_build_role_build_id_fkey FOREIGN KEY (build_id) REFERENCES public.build(id);


--
-- Name: organization_build_role organization_build_role_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.organization_build_role
    ADD CONSTRAINT organization_build_role_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: rack rack_build_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack
    ADD CONSTRAINT rack_build_id_fkey FOREIGN KEY (build_id) REFERENCES public.build(id);


--
-- Name: rack rack_datacenter_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack
    ADD CONSTRAINT rack_datacenter_room_id_fkey FOREIGN KEY (datacenter_room_id) REFERENCES public.datacenter_room(id);


--
-- Name: rack_layout rack_layout_hardware_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack_layout
    ADD CONSTRAINT rack_layout_hardware_product_id_fkey FOREIGN KEY (hardware_product_id) REFERENCES public.hardware_product(id);


--
-- Name: rack_layout rack_layout_rack_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack_layout
    ADD CONSTRAINT rack_layout_rack_id_fkey FOREIGN KEY (rack_id) REFERENCES public.rack(id);


--
-- Name: device_location rack_layout_rack_id_rack_unit_start_key; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_location
    ADD CONSTRAINT rack_layout_rack_id_rack_unit_start_key FOREIGN KEY (rack_id, rack_unit_start) REFERENCES public.rack_layout(rack_id, rack_unit_start);


--
-- Name: rack rack_role_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.rack
    ADD CONSTRAINT rack_role_fkey FOREIGN KEY (rack_role_id) REFERENCES public.rack_role(id);


--
-- Name: relay relay_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.relay
    ADD CONSTRAINT relay_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_account(id);


--
-- Name: user_build_role user_build_role_build_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_build_role
    ADD CONSTRAINT user_build_role_build_id_fkey FOREIGN KEY (build_id) REFERENCES public.build(id);


--
-- Name: user_build_role user_build_role_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_build_role
    ADD CONSTRAINT user_build_role_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_account(id);


--
-- Name: user_organization_role user_organization_role_organization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_organization_role
    ADD CONSTRAINT user_organization_role_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES public.organization(id);


--
-- Name: user_organization_role user_organization_role_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_organization_role
    ADD CONSTRAINT user_organization_role_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_account(id);


--
-- Name: user_session_token user_session_token_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_session_token
    ADD CONSTRAINT user_session_token_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_account(id);


--
-- Name: user_setting user_setting_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_setting
    ADD CONSTRAINT user_setting_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_account(id);


--
-- Name: validation_plan_member validation_plan_member_validation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_plan_member
    ADD CONSTRAINT validation_plan_member_validation_id_fkey FOREIGN KEY (validation_id) REFERENCES public.validation(id);


--
-- Name: validation_plan_member validation_plan_member_validation_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_plan_member
    ADD CONSTRAINT validation_plan_member_validation_plan_id_fkey FOREIGN KEY (validation_plan_id) REFERENCES public.validation_plan(id);


--
-- Name: validation_state validation_state_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_state
    ADD CONSTRAINT validation_state_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device(id);


--
-- Name: validation_state validation_state_device_report_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_state
    ADD CONSTRAINT validation_state_device_report_id_fkey FOREIGN KEY (device_report_id) REFERENCES public.device_report(id) ON DELETE CASCADE;


--
-- Name: validation_state validation_state_hardware_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_state
    ADD CONSTRAINT validation_state_hardware_product_id_fkey FOREIGN KEY (hardware_product_id) REFERENCES public.hardware_product(id);


--
-- Name: TABLE build; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.build TO conch_read_only;


--
-- Name: TABLE datacenter; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.datacenter TO conch_read_only;


--
-- Name: TABLE datacenter_room; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.datacenter_room TO conch_read_only;


--
-- Name: TABLE device; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.device TO conch_read_only;


--
-- Name: TABLE device_disk; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.device_disk TO conch_read_only;


--
-- Name: TABLE device_location; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.device_location TO conch_read_only;


--
-- Name: TABLE device_neighbor; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.device_neighbor TO conch_read_only;


--
-- Name: TABLE device_nic; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.device_nic TO conch_read_only;


--
-- Name: TABLE device_relay_connection; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.device_relay_connection TO conch_read_only;


--
-- Name: TABLE device_report; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.device_report TO conch_read_only;


--
-- Name: TABLE device_setting; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.device_setting TO conch_read_only;


--
-- Name: TABLE hardware_product; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.hardware_product TO conch_read_only;


--
-- Name: TABLE hardware_vendor; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.hardware_vendor TO conch_read_only;


--
-- Name: TABLE json_schema; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.json_schema TO conch_read_only;


--
-- Name: TABLE legacy_validation_result; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.legacy_validation_result TO conch_read_only;


--
-- Name: TABLE legacy_validation_state_member; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.legacy_validation_state_member TO conch_read_only;


--
-- Name: TABLE migration; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.migration TO conch_read_only;


--
-- Name: TABLE organization; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.organization TO conch_read_only;


--
-- Name: TABLE organization_build_role; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.organization_build_role TO conch_read_only;


--
-- Name: TABLE rack; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.rack TO conch_read_only;


--
-- Name: TABLE rack_layout; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.rack_layout TO conch_read_only;


--
-- Name: TABLE rack_role; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.rack_role TO conch_read_only;


--
-- Name: TABLE relay; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.relay TO conch_read_only;


--
-- Name: TABLE user_account; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.user_account TO conch_read_only;


--
-- Name: TABLE user_build_role; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.user_build_role TO conch_read_only;


--
-- Name: TABLE user_organization_role; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.user_organization_role TO conch_read_only;


--
-- Name: TABLE user_session_token; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.user_session_token TO conch_read_only;


--
-- Name: TABLE user_setting; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.user_setting TO conch_read_only;


--
-- Name: TABLE validation; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.validation TO conch_read_only;


--
-- Name: TABLE validation_plan; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.validation_plan TO conch_read_only;


--
-- Name: TABLE validation_plan_member; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.validation_plan_member TO conch_read_only;


--
-- Name: TABLE validation_state; Type: ACL; Schema: public; Owner: conch
--

GRANT SELECT ON TABLE public.validation_state TO conch_read_only;


--
-- PostgreSQL database dump complete
--

