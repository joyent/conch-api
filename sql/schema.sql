--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.11
-- Dumped by pg_dump version 9.6.11

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


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
-- Name: user_workspace_role_enum; Type: TYPE; Schema: public; Owner: conch
--

CREATE TYPE public.user_workspace_role_enum AS ENUM (
    'ro',
    'rw',
    'admin'
);


ALTER TYPE public.user_workspace_role_enum OWNER TO conch;

--
-- Name: validation_status_enum; Type: TYPE; Schema: public; Owner: conch
--

CREATE TYPE public.validation_status_enum AS ENUM (
    'error',
    'fail',
    'processing',
    'pass'
);


ALTER TYPE public.validation_status_enum OWNER TO conch;

--
-- Name: add_rack_to_global_workspace(); Type: FUNCTION; Schema: public; Owner: conch
--

CREATE FUNCTION public.add_rack_to_global_workspace() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      begin
        insert into workspace_rack (workspace_id, rack_id)
            select workspace.id, NEW.id
            from workspace
            where workspace.name = 'GLOBAL'
            on conflict (workspace_id, rack_id) do nothing;
        return NEW;
      end;
      $$;


ALTER FUNCTION public.add_rack_to_global_workspace() OWNER TO conch;

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
    vendor_name text,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.datacenter_room OWNER TO conch;

--
-- Name: device; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device (
    id text NOT NULL,
    system_uuid uuid,
    hardware_product_id uuid NOT NULL,
    state text NOT NULL,
    health public.device_health_enum NOT NULL,
    graduated timestamp with time zone,
    deactivated timestamp with time zone,
    last_seen timestamp with time zone,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    uptime_since timestamp with time zone,
    validated timestamp with time zone,
    latest_triton_reboot timestamp with time zone,
    triton_uuid uuid,
    asset_tag text,
    triton_setup timestamp with time zone,
    hostname text
);


ALTER TABLE public.device OWNER TO conch;

--
-- Name: device_disk; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_disk (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    device_id text NOT NULL,
    serial_number text NOT NULL,
    slot integer,
    size integer,
    vendor text,
    model text,
    firmware text,
    transport text,
    health text,
    drive_type text,
    temp integer,
    deactivated timestamp with time zone,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    enclosure integer,
    hba integer
);


ALTER TABLE public.device_disk OWNER TO conch;

--
-- Name: device_environment; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_environment (
    device_id text NOT NULL,
    cpu0_temp integer,
    cpu1_temp integer,
    inlet_temp integer,
    exhaust_temp integer,
    psu0_voltage numeric,
    psu1_voltage numeric,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.device_environment OWNER TO conch;

--
-- Name: device_location; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_location (
    device_id text NOT NULL,
    rack_id uuid NOT NULL,
    rack_unit_start integer NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
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
    want_switch text,
    want_port text,
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
    device_id text NOT NULL,
    iface_name text NOT NULL,
    iface_type text NOT NULL,
    iface_vendor text NOT NULL,
    iface_driver text,
    deactivated timestamp with time zone,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    state text,
    speed text,
    ipaddr inet,
    mtu integer
);


ALTER TABLE public.device_nic OWNER TO conch;

--
-- Name: device_relay_connection; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_relay_connection (
    device_id text NOT NULL,
    relay_id text NOT NULL,
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.device_relay_connection OWNER TO conch;

--
-- Name: device_report; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_report (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    device_id text NOT NULL,
    report jsonb,
    created timestamp with time zone DEFAULT now() NOT NULL,
    invalid_report text,
    retain boolean
);


ALTER TABLE public.device_report OWNER TO conch;

--
-- Name: device_setting; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.device_setting (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    device_id text NOT NULL,
    value text,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    deactivated timestamp with time zone,
    name text NOT NULL
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
    specification jsonb,
    sku text,
    generation_name text,
    legacy_product_name text
);


ALTER TABLE public.hardware_product OWNER TO conch;

--
-- Name: hardware_product_profile; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.hardware_product_profile (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    hardware_product_id uuid NOT NULL,
    rack_unit integer NOT NULL,
    purpose text NOT NULL,
    bios_firmware text NOT NULL,
    hba_firmware text,
    cpu_num integer NOT NULL,
    cpu_type text NOT NULL,
    dimms_num integer NOT NULL,
    ram_total integer NOT NULL,
    nics_num integer NOT NULL,
    sata_hdd_num integer,
    sata_hdd_size integer,
    sata_hdd_slots text,
    sas_hdd_num integer,
    sas_hdd_size integer,
    sas_hdd_slots text,
    sata_ssd_num integer,
    sata_ssd_size integer,
    sata_ssd_slots text,
    psu_total integer,
    deactivated timestamp with time zone,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    usb_num integer NOT NULL,
    sas_ssd_num integer,
    sas_ssd_size integer,
    sas_ssd_slots text,
    nvme_ssd_num integer,
    nvme_ssd_size integer,
    nvme_ssd_slots text,
    raid_lun_num integer
);


ALTER TABLE public.hardware_product_profile OWNER TO conch;

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
-- Name: migration; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.migration (
    id integer NOT NULL,
    created timestamp with time zone DEFAULT now()
);


ALTER TABLE public.migration OWNER TO conch;

--
-- Name: migration_id_seq; Type: SEQUENCE; Schema: public; Owner: conch
--

CREATE SEQUENCE public.migration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.migration_id_seq OWNER TO conch;

--
-- Name: migration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: conch
--

ALTER SEQUENCE public.migration_id_seq OWNED BY public.migration.id;


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
    asset_tag text
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
    updated timestamp with time zone DEFAULT now() NOT NULL
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
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.rack_role OWNER TO conch;

--
-- Name: relay; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.relay (
    id text NOT NULL,
    alias text,
    version text,
    ipaddr inet,
    ssh_port integer,
    deactivated timestamp with time zone,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.relay OWNER TO conch;

--
-- Name: user_account; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.user_account (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    password_hash text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    last_login timestamp with time zone,
    email text NOT NULL,
    deactivated timestamp with time zone,
    refuse_session_auth boolean DEFAULT false NOT NULL,
    force_password_change boolean DEFAULT false NOT NULL,
    is_admin boolean DEFAULT false NOT NULL
);


ALTER TABLE public.user_account OWNER TO conch;

--
-- Name: user_relay_connection; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.user_relay_connection (
    user_id uuid NOT NULL,
    relay_id text NOT NULL,
    first_seen timestamp with time zone DEFAULT now() NOT NULL,
    last_seen timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_relay_connection OWNER TO conch;

--
-- Name: user_session_token; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.user_session_token (
    user_id uuid NOT NULL,
    token_hash bytea NOT NULL,
    expires timestamp with time zone NOT NULL
);


ALTER TABLE public.user_session_token OWNER TO conch;

--
-- Name: user_setting; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.user_setting (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    name text NOT NULL,
    value jsonb NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    deactivated timestamp with time zone
);


ALTER TABLE public.user_setting OWNER TO conch;

--
-- Name: user_workspace_role; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.user_workspace_role (
    user_id uuid NOT NULL,
    workspace_id uuid NOT NULL,
    role public.user_workspace_role_enum DEFAULT 'ro'::public.user_workspace_role_enum NOT NULL
);


ALTER TABLE public.user_workspace_role OWNER TO conch;

--
-- Name: validation; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.validation (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    version integer NOT NULL,
    description text NOT NULL,
    module text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    updated timestamp with time zone DEFAULT now() NOT NULL,
    deactivated timestamp with time zone
);


ALTER TABLE public.validation OWNER TO conch;

--
-- Name: validation_plan; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.validation_plan (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
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
-- Name: validation_result; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.validation_result (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    device_id text NOT NULL,
    hardware_product_id uuid NOT NULL,
    validation_id uuid NOT NULL,
    message text NOT NULL,
    hint text,
    status public.validation_status_enum NOT NULL,
    category text NOT NULL,
    component_id text,
    result_order integer NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.validation_result OWNER TO conch;

--
-- Name: validation_state; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.validation_state (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    device_id text NOT NULL,
    validation_plan_id uuid NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    status public.validation_status_enum NOT NULL,
    completed timestamp with time zone,
    device_report_id uuid NOT NULL
);


ALTER TABLE public.validation_state OWNER TO conch;

--
-- Name: validation_state_member; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.validation_state_member (
    validation_state_id uuid NOT NULL,
    validation_result_id uuid NOT NULL
);


ALTER TABLE public.validation_state_member OWNER TO conch;

--
-- Name: workspace; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.workspace (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    description text,
    parent_workspace_id uuid
);


ALTER TABLE public.workspace OWNER TO conch;

--
-- Name: workspace_rack; Type: TABLE; Schema: public; Owner: conch
--

CREATE TABLE public.workspace_rack (
    workspace_id uuid NOT NULL,
    rack_id uuid NOT NULL
);


ALTER TABLE public.workspace_rack OWNER TO conch;

--
-- Name: migration id; Type: DEFAULT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.migration ALTER COLUMN id SET DEFAULT nextval('public.migration_id_seq'::regclass);


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
-- Name: device_environment device_environment_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_environment
    ADD CONSTRAINT device_environment_pkey PRIMARY KEY (device_id);


--
-- Name: device_location device_location_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_location
    ADD CONSTRAINT device_location_pkey PRIMARY KEY (device_id);


--
-- Name: device_location device_location_rack_id_rack_unit_start_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_location
    ADD CONSTRAINT device_location_rack_id_rack_unit_start_key UNIQUE (rack_id, rack_unit_start);


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
-- Name: hardware_product_profile hardware_product_profile_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.hardware_product_profile
    ADD CONSTRAINT hardware_product_profile_pkey PRIMARY KEY (id);


--
-- Name: hardware_product_profile hardware_product_profile_product_id_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.hardware_product_profile
    ADD CONSTRAINT hardware_product_profile_product_id_key UNIQUE (hardware_product_id);


--
-- Name: hardware_vendor hardware_vendor_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.hardware_vendor
    ADD CONSTRAINT hardware_vendor_pkey PRIMARY KEY (id);


--
-- Name: migration migration_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.migration
    ADD CONSTRAINT migration_pkey PRIMARY KEY (id);


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
-- Name: user_account user_account_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_account
    ADD CONSTRAINT user_account_pkey PRIMARY KEY (id);


--
-- Name: user_relay_connection user_relay_connection_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_relay_connection
    ADD CONSTRAINT user_relay_connection_pkey PRIMARY KEY (user_id, relay_id);


--
-- Name: user_session_token user_session_token_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_session_token
    ADD CONSTRAINT user_session_token_pkey PRIMARY KEY (user_id, token_hash);


--
-- Name: user_setting user_setting_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_setting
    ADD CONSTRAINT user_setting_pkey PRIMARY KEY (id);


--
-- Name: user_workspace_role user_workspace_role_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_workspace_role
    ADD CONSTRAINT user_workspace_role_pkey PRIMARY KEY (user_id, workspace_id);


--
-- Name: user_workspace_role user_workspace_role_user_id_workspace_id_role_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_workspace_role
    ADD CONSTRAINT user_workspace_role_user_id_workspace_id_role_key UNIQUE (user_id, workspace_id, role);


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
-- Name: validation_result validation_result_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_result
    ADD CONSTRAINT validation_result_pkey PRIMARY KEY (id);


--
-- Name: validation_state_member validation_state_member_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_state_member
    ADD CONSTRAINT validation_state_member_pkey PRIMARY KEY (validation_state_id, validation_result_id);


--
-- Name: validation_state validation_state_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_state
    ADD CONSTRAINT validation_state_pkey PRIMARY KEY (id);


--
-- Name: workspace workspace_name_key; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.workspace
    ADD CONSTRAINT workspace_name_key UNIQUE (name);


--
-- Name: workspace workspace_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.workspace
    ADD CONSTRAINT workspace_pkey PRIMARY KEY (id);


--
-- Name: workspace_rack workspace_rack_pkey; Type: CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.workspace_rack
    ADD CONSTRAINT workspace_rack_pkey PRIMARY KEY (workspace_id, rack_id);


--
-- Name: datacenter_room_datacenter_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX datacenter_room_datacenter_id_idx ON public.datacenter_room USING btree (datacenter_id);


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
-- Name: device_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_id_idx ON public.device USING btree (id) WHERE (deactivated IS NULL);


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
-- Name: device_relay_connection_device_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_relay_connection_device_id_idx ON public.device_relay_connection USING btree (device_id);


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
-- Name: device_report_device_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX device_report_device_id_idx ON public.device_report USING btree (device_id);


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
-- Name: rack_rack_role_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX rack_rack_role_id_idx ON public.rack USING btree (rack_role_id);


--
-- Name: user_account_email_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX user_account_email_key ON public.user_account USING btree (email) WHERE (deactivated IS NULL);


--
-- Name: user_account_name_key; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_account_name_key ON public.user_account USING btree (name);


--
-- Name: user_relay_connection_relay_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_relay_connection_relay_id_idx ON public.user_relay_connection USING btree (relay_id);


--
-- Name: user_relay_connection_user_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_relay_connection_user_id_idx ON public.user_relay_connection USING btree (user_id);


--
-- Name: user_session_token_expires_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_session_token_expires_idx ON public.user_session_token USING btree (expires);


--
-- Name: user_session_token_user_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_session_token_user_id_idx ON public.user_session_token USING btree (user_id);


--
-- Name: user_setting_user_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_setting_user_id_idx ON public.user_setting USING btree (user_id);


--
-- Name: user_setting_user_id_name_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX user_setting_user_id_name_idx ON public.user_setting USING btree (user_id, name) WHERE (deactivated IS NULL);


--
-- Name: user_workspace_role_user_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_workspace_role_user_id_idx ON public.user_workspace_role USING btree (user_id);


--
-- Name: user_workspace_role_workspace_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX user_workspace_role_workspace_id_idx ON public.user_workspace_role USING btree (workspace_id);


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
-- Name: validation_result_device_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_result_device_id_idx ON public.validation_result USING btree (device_id);


--
-- Name: validation_result_hardware_product_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_result_hardware_product_id_idx ON public.validation_result USING btree (hardware_product_id);


--
-- Name: validation_result_validation_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_result_validation_id_idx ON public.validation_result USING btree (validation_id);


--
-- Name: validation_state_completed_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_completed_idx ON public.validation_state USING btree (completed);


--
-- Name: validation_state_created_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_created_idx ON public.validation_state USING btree (created);


--
-- Name: validation_state_device_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_device_id_idx ON public.validation_state USING btree (device_id);


--
-- Name: validation_state_device_id_validation_plan_id_completed_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_device_id_validation_plan_id_completed_idx ON public.validation_state USING btree (device_id, validation_plan_id, completed DESC) WHERE (completed IS NOT NULL);


--
-- Name: validation_state_device_report_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_device_report_id_idx ON public.validation_state USING btree (device_report_id);


--
-- Name: validation_state_member_validation_result_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_member_validation_result_id_idx ON public.validation_state_member USING btree (validation_result_id);


--
-- Name: validation_state_member_validation_state_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_member_validation_state_id_idx ON public.validation_state_member USING btree (validation_state_id);


--
-- Name: validation_state_validation_plan_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX validation_state_validation_plan_id_idx ON public.validation_state USING btree (validation_plan_id);


--
-- Name: workspace_parent_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE UNIQUE INDEX workspace_parent_id_idx ON public.workspace USING btree (((parent_workspace_id IS NULL))) WHERE (parent_workspace_id IS NULL);


--
-- Name: workspace_parent_workspace_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX workspace_parent_workspace_id_idx ON public.workspace USING btree (parent_workspace_id);


--
-- Name: workspace_rack_rack_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX workspace_rack_rack_id_idx ON public.workspace_rack USING btree (rack_id);


--
-- Name: workspace_rack_workspace_id_idx; Type: INDEX; Schema: public; Owner: conch
--

CREATE INDEX workspace_rack_workspace_id_idx ON public.workspace_rack USING btree (workspace_id);


--
-- Name: rack all_racks_in_global_workspace; Type: TRIGGER; Schema: public; Owner: conch
--

CREATE TRIGGER all_racks_in_global_workspace AFTER INSERT ON public.rack FOR EACH ROW EXECUTE PROCEDURE public.add_rack_to_global_workspace();


--
-- Name: datacenter_room datacenter_room_datacenter_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.datacenter_room
    ADD CONSTRAINT datacenter_room_datacenter_fkey FOREIGN KEY (datacenter_id) REFERENCES public.datacenter(id);


--
-- Name: device_disk device_disk_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_disk
    ADD CONSTRAINT device_disk_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device(id);


--
-- Name: device_environment device_environment_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.device_environment
    ADD CONSTRAINT device_environment_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device(id);


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
-- Name: hardware_product_profile hardware_product_profile_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.hardware_product_profile
    ADD CONSTRAINT hardware_product_profile_product_id_fkey FOREIGN KEY (hardware_product_id) REFERENCES public.hardware_product(id) ON DELETE CASCADE;


--
-- Name: hardware_product hardware_product_vendor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.hardware_product
    ADD CONSTRAINT hardware_product_vendor_fkey FOREIGN KEY (hardware_vendor_id) REFERENCES public.hardware_vendor(id);


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
-- Name: user_relay_connection user_relay_connection_relay_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_relay_connection
    ADD CONSTRAINT user_relay_connection_relay_id_fkey FOREIGN KEY (relay_id) REFERENCES public.relay(id);


--
-- Name: user_relay_connection user_relay_connection_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_relay_connection
    ADD CONSTRAINT user_relay_connection_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_account(id);


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
-- Name: user_workspace_role user_workspace_role_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_workspace_role
    ADD CONSTRAINT user_workspace_role_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_account(id);


--
-- Name: user_workspace_role user_workspace_role_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.user_workspace_role
    ADD CONSTRAINT user_workspace_role_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspace(id);


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
-- Name: validation_result validation_result_device_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_result
    ADD CONSTRAINT validation_result_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.device(id);


--
-- Name: validation_result validation_result_hardware_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_result
    ADD CONSTRAINT validation_result_hardware_product_id_fkey FOREIGN KEY (hardware_product_id) REFERENCES public.hardware_product(id);


--
-- Name: validation_result validation_result_validation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_result
    ADD CONSTRAINT validation_result_validation_id_fkey FOREIGN KEY (validation_id) REFERENCES public.validation(id);


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
-- Name: validation_state_member validation_state_member_validation_result_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_state_member
    ADD CONSTRAINT validation_state_member_validation_result_id_fkey FOREIGN KEY (validation_result_id) REFERENCES public.validation_result(id);


--
-- Name: validation_state_member validation_state_member_validation_state_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_state_member
    ADD CONSTRAINT validation_state_member_validation_state_id_fkey FOREIGN KEY (validation_state_id) REFERENCES public.validation_state(id) ON DELETE CASCADE;


--
-- Name: validation_state validation_state_validation_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.validation_state
    ADD CONSTRAINT validation_state_validation_plan_id_fkey FOREIGN KEY (validation_plan_id) REFERENCES public.validation_plan(id);


--
-- Name: workspace workspace_parent_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.workspace
    ADD CONSTRAINT workspace_parent_workspace_id_fkey FOREIGN KEY (parent_workspace_id) REFERENCES public.workspace(id);


--
-- Name: workspace_rack workspace_rack_rack_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.workspace_rack
    ADD CONSTRAINT workspace_rack_rack_id_fkey FOREIGN KEY (rack_id) REFERENCES public.rack(id) ON DELETE CASCADE;


--
-- Name: workspace_rack workspace_rack_workspace_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: conch
--

ALTER TABLE ONLY public.workspace_rack
    ADD CONSTRAINT workspace_rack_workspace_id_fkey FOREIGN KEY (workspace_id) REFERENCES public.workspace(id);


--
-- PostgreSQL database dump complete
--

