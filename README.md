# conch: datacenter preflight

infrastructure validation

# Overview

conch is a tool which allows us to boot an entire datacenter and run diagnostics, benchmarking, and configuration against a new (or existing) fleet of systems.

The premise is we want to boot all new systems into a "preflight checklist" environment, in which we can validate hardware is correct and operational.

*NOTE Development has just begun. The following describes the target initial featureset.*

When we have a new environment to validate, we import the hardware integrators data (rack location, MAC addresses, Serial Numbers, and so on) into Conch's database. We build hardware profiles which define how we expect each class of system in the environment to be built.

Once systems are isolated on a network/VLAN, we boot them into a custom VM. The VM starts up its Chef Client, downloading our cookbooks from a Chef Server accessible on the VLAN.

The cookbooks execute a number of tasks, including gathering hardware information, system / environmental data, testing hard drive status, running benchmarks, and so forth. In effect, they collect data and ensure the host is healthy.

Once the cookbook run is complete, the logs fro the run are pushed to the Conch Ingestion API, where they are parsed and stored in Postgres.

The web UI allows operators to view the health of the new environment. It surfaces actionable reports (bad cabling, dead disks, etc.)

## Future Work

Later we will want to integrate conch data with our CMDB (device42) and JIRA, to make it easier to resolve issues in an environment.

We will also want to make it possible to boot CNs into a useful diagnostic state outside of Triton single-user mode, or allowing an operating to boot a system into an automated disk "shredding" state.

# Development and Project Management

Currently we are running this project through LiquidPlanner, which requires an invite. Victor Lopez and Bryan Horstman-Allen are primary on it.

# Components

## Off the Shelf

* DHCP/PXE server
* Chef Server
* Postgres
* A dedicated network broadcast domain (a VLAN in our setup)

## Conch Assets

* [Conch VM](https://devops.int.joyent.us/repo/cloudops/conch-packer)
* [Host Data Collection Chef Cookbooks](https://devops.int.joyent.us/repo/cloudops/conch-chef)
* [Conch Ingestion API](https://devops.int.joyent.us/repo/cloudops/conch-api)
* [Conch Web UI](https://devops.int.joyent.us/repo/cloudops/conch-web)

# Installation

## Database

```
pkgin in postgresql96-server postgresql96-contrib
```

```
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```
