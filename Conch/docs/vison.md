# Conch Product Definition

Conch helps you build and manage datacenters.

Conch's goal is to provide an end-to-end solution for full datacenter resource
lifecycle: from design to initial power-on to end-of-life.

Conch is open source, licensed under MPL2.

## Language

Conch API services are written in Perl/Mojolicious, using Modern Perl
techniques.

Conch CLI is written in Go.

Conch Database is Postgres.

## Product Comparison

* The Foreman
* Collins
* netbox
* device42
* CMMS

## Features

### Architecture

- [x] [Multi-tentant web service]()
- [x] [Basic user roles]()
- [x] [Rest APIs]()
- [x] [CLI tool]()

### Datacenter Design and Visualization

- [ ] IPAM
- [ ] BOM designer
- [ ] Rack designer
- [ ] Datacenter designer
- [ ] Design review and approval system

### Asset Management

- [x] Server tracking
- [x] TOR tracking
- [ ] Discrete component tracking
- [ ] Preventative maintenance
- [ ] Build reports
- [ ] Failure reports
- [ ] Validation/audit reports

### Procurement and RFQs

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
- [ ] Network stress testing
- [ ] Burnin/stress metrics stored in TSDB
- [x] PDU firmware upgrade
- [x] PDU configuration
- [ ] Server/PDU power map

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

## 2018H1 Goals

## 2018H2 Goals

## References
