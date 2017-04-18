# conch: datacenter preflight

infrastructure validation

# Overview

conch is a tool which allows us to boot an entire datacenter and run diagnostics, benchmarking, and configuration against a new (or existing) fleet of systems.

The premise is we want to boot all new systems into a "preflight checklist" environment, in which we can validate hardware is correct and operational.

When we have a new environment to validate, we import the hardware integrators data (rack location, MAC addresses, Serial Numbers, and so on) into Conch's database. We build hardware profiles which define how we expect each class of system in the environment to be built.

Once systems are isolated on a network/VLAN, we PXE boot using FAI. Once booted, Chef executes and starts Telegraf and runs our client agent every minute.

The client agent gathers a fair amount of data about the system, including hardware configuraiton, environmental data, and network peers.

Once the collection is complete, a JSON blob is POSTed to the Conch API. The data is stored, and validation routines are run against it. The validation results are logged.

The web UI allows operators to view the health of the new environment. It surfaces actionable reports (bad cabling, dead disks, etc.)

## Current Features

* Simple REST API
* Validates data on ingestion
* Simple web UI
* Spaghetti demon to export data from client systems
* Basic system configuration
* Preloading datacenter inventory

### Data exporter exports

* Temps
* Basic system hardware (CPU, RAM)
* Hard drives
* Network interfaces
* Network peers
* Firmware versions

...more to come.

## Future Work

Later we will want to integrate conch data with our CMDB (device42) and JIRA, to make it easier to resolve issues in an environment.

We will also want to make it possible to boot CNs into a useful diagnostic state outside of Triton single-user mode, or allowing an operating to boot a system into an automated disk "shredding" state.

# Development and Project Management

This project is managed in LiquidPlanner.

# Components

## Off the Shelf

* FAI (DHCP/PXE server) VM
* Chef client
* Postgres
* A dedicated network broadcast domain (a VLAN in our setup)

# Installation

TODO
