# Conch Product Definition

Conch helps you build and manage datacenters.

Conch's goal is to provide an end-to-end solution for full datacenter resource
lifecycle: from design to initial power-on to end-of-life for all components of
all devices.

Conch is open source, licensed under MPL2.

## Design

Major Conch features must be written as Request For Discussion documents (RFD).

RFDs are published in the [Joyent RFD GitHub repo](https://github.com/joyent/rfd).

| State    | RFD |
|----------|-----|
| Deployed | [RFD 132 Conch: Unified Rack Integration Process](https://github.com/joyent/rfd/blob/master/rfd/0132/README.md) |
| Deployed | [RFD 133 Conch: Improved Device Validation](https://github.com/joyent/rfd/blob/master/rfd/0133/README.md) |
| Deployed | [RFD 134 Conch: User Access Control](https://github.com/joyent/rfd/blob/master/rfd/0134/README.md) |
| Draft    | [RFD 135 Conch: Job Queue and Real-Time Notifications](https://github.com/joyent/rfd/blob/master/rfd/0135/README.md) |
| Draft    | [RFD 136 Conch: Orchestration](https://github.com/joyent/rfd/blob/master/rfd/0136/README.md) |
| Draft    | [RFD 140 Conch: Datacenter Designer](https://github.com/joyent/rfd/blob/master/rfd/0140/README.md) |
| Private  | Triton CN Setup Automation |

Minor features require discussion (often in GitHub Issues or email) but not
RFDs.

Conch is designed in public as much as possible, though there some components
that are currently closed (until they can be scrubbed for security.)

## Development Process

All Pull Requests to Conch repos require code review by at least one engineer.

A buildbot deployment runs the Conch testsuites for every commit.

Binary releases of the Conch Shell are available [here](https://github.com/joyent/conch-shell/releases) for many platforms.

## Similar Products

* The Foreman
* Collins
* netbox
* device42
* Commerical CMMS (e.g., Fiix)
* GitHub Metal Cloud

## Components

### API

Conch's core is its REST API. The API is documented [here](https://conch.joyent.us/doc).

It exposes basic CRUD for all resources we know how to manage:

* Users
* Workspaces
* Datacenters, rooms (soon: cages)
* Racks
* Hardware products (servers, switches)
* Devices
* Validation failures
* Stats

Workspaces are arbitrary collections of Datacenter Rooms or Racks. This is
useful for a number of reasons: You can define workspaces for AZs, for
expansions, or for specific builds. You can invite specific users to a given
workspace, allowing you to limit the devices an outside vendor can interact
with. Workspaces are a very powerful, useful primitive.

It also includes report ingestion and validation endpoints. These feed into the
[validation engine](https://github.com/joyent/conch/blob/master/Conch/docs/validation/BaseValidation.md)
which allows us to decide if a device is healthy or not, based off its hardware
profile, environmental or arbitrary data.

Writing and testing new validations is documented
[here](https://github.com/joyent/conch/blob/master/Conch/docs/validation/Guide.md).

The APIs are written in Perl's [Mojolicious framework](https://mojolicious.org/), and are available
[here](https://github.com/joyent/conch).

A basic workspace-aware stats framework is available [here](https://github.com/joyent/conch-stats).

### UI

The Conch UI is rapidly evolving. Its initial design was targeted at hardware
integrators and datacenter operation staff -- the main focus was on defining
rack layout and identifying problems with devices in those racks.

As time goes on, the UI will expand to include better search and reporting
options, and more advanced features like datacenter, rack, and BOM design.

The UI is an API consumer, and is not magical in any respect.

The UI is written in [Mithril.js](https://mithril.js.org/), and is available
[here](https://github.com/joyent/conch-ui).

### Conch Shell

The Conch Shell is a CLI tool provides many useful primitives for interacting
with the Conch API. It supports multiple user profiles and endpoints, and has
JSON output options to allow users to create arbitrary processes with it.

The Shell has many options. Here are some examples of using it:

* [Overview](https://gist.github.com/bdha/1a625f22e922cbba315b660f30c3681c)
* [Rack slot contents](https://gist.github.com/bdha/5bcb8bf8321026c68e5b15c76bc77470)
* [Validation plans](https://gist.github.com/bdha/ea93ddd19be5afa7ad21f52bfd6c7bde)
* [Hardware profiles](https://gist.github.com/bdha/ac41b6953325580b614ff4e44b09c095)

The Shell is an API consumer, and is not magical in any respect.

The Shell is written on Go, and is available [here](https://github.com/joyent/conch-shell).

A Go library is also [available](https://github.com/joyent/go-conch) for interacting with the API.

### Database

Conch's core database is Postgres.

Conch uses a [simple migration system](https://github.com/joyent/conch/tree/master/sql)
for managing database changes.

### Relay

Conch Relay is a simple API service that takes traffic from the livesys or other
Conch clients and interacts with the Conch API. It is currently used mainly in
integration and initial validation stages of datacenter builds.

The Relay codebase is currently closed, but is planned on being open ASAP.

The Relay comes in two flavors:

#### Diagnostic Relay Device (DRD)

AKA Preflight Relay Device (PRD).

This is a physical deployment of the Relay service. DRDs are simple x86 or
Rasberry Pi devices that run the Relay and various other agents for standing up
and configuring racks.

In this mode, we support configuration of TORs. As such, the device is plugged
into individual racks. In certain configurations, the DRD must have serial
cables plugged into the TORs to configure them. Other switches only require
ethernet access to do so.

This mode is exclusing used in off-site integration facilities, before the racks
are shipped to the datacenter.

The Relay also includes a support tunnel feature, so engineers can remotely log
into the integration facility if needed.

#### Relay Service (VM)

In this mode, the Relay runs in a SmartOS or VM, and operates in a post-shipment
re-validation mode. In the future, this mode may also allow the planned
production inventory agent to submit reports to the Conch APIs from a local
service.

### Livesys

The live system is a read-only Linux image the Relay PXE boots on servers.

The livesys includes a number of agents:

* Firmware upgrade
* Reporter
* Rebooter
* Burnin
* ...

The livesys is configured via `chef-solo` cookbooks.

The livesys codebase is currently closed, but is planned on being open ASAP.

## Features

### Architecture

- [x] Multi-tentant web service
- [x] Basic user roles
- [x] Rest APIs
- [x] CLI tool
- [x] Workspaces
- [x] Validation engine
- [x] User settings (KV)
- [x] Device settings (KV)
- [ ] Organizations
- [ ] Organization settings (KV)
- [x] Korean localization (partial)

### Datacenter Design and Visualization

- [x] Basic hardware profile support
- [ ] Robust hardware profile support
- [ ] IPAM
- [ ] BOM designer
- [ ] Rack designer
- [ ] Datacenter designer
- [ ] Design review and approval

### Asset Management

- [x] Server tracking
- [x] TOR tracking
- [ ] Component database
- [ ] Parts and supply tracking
- [ ] Preventative maintenance
- [ ] Maintenance schedules
- [ ] Work orders via JIRA integration or similar
- [ ] Spare management
- [ ] Build reports
- [ ] Failure reports
- [ ] Validation/audit reports

### Procurement and RFQs

- [ ] Emit full BOMs from a datacenter workspace

### Preflight

"Preflight" is the initial stage of a device entering service. This may happen
during hardware integration, or during datacenter standup.

- [x] Embedded Relay Devices for off-site usage (rack integration)
- [x] Linux-based live system (PXE booted)
- [x] Server firmware upgrade
- [x] Server configuration
- [x] Server validation
- [x] Server burnin
- [x] TOR firmware upgrade
- [x] TOR configuration
- [x] TOR basic validation
- [ ] TOR extended validation
- [ ] TOR burnin
- [x] Server/TOR network map validation
- [ ] Network stress testing (intra-rack)
- [ ] Network stress testing (inter-rack)
- [ ] Network stress testing (cross-DC)
- [ ] Burnin/stress metrics stored in TSDB
- [x] PDU firmware upgrade
- [x] PDU configuration
- [ ] Server/PDU power map
- [ ] Multi-OS boot
- [ ] Multi-OS burnin

### Services Standup

- [ ] Admin server
- [ ] Triton Headnode
- [ ] Triton Compute Node
- [ ] Manta initial install
- [ ] Manta storage expansion
- [ ] Manta metadata expansion

### Device Production

Production is the longest (hopefully!) stage of a device during its lifecycle.

- [x] VM-based Relay software for on-site usage
- [ ] Agent-based version of the livesys reporter
- [ ] Diagnostics mode

### Device Retirement

- [ ] API and UI for marking devices retired

## 2018 Roadmap

### 2018H1 Goals

* Triton CN setup automation
* Network stress v1
* Arista/Cisco TOR support
* Audit report generation
* Production inventory agent
* Datacenter designer

### 2018H2 Goals

* Manta expansion automation
* Switch VLAN API
* Admin server install
* Store burnin in TSDB
* Reporting
* Triton testing v2
* Manta testing v2
* Diagnostics mode
* Multi-OS boot / burnin
* BOM builder
