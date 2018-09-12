# Conch API Server

Conch helps you build and manage datacenters.

Conch's goal is to provide an end-to-end solution for full datacenter resource
lifecycle: from design to initial power-on to end-of-life for all components of
all devices.

Conch is open source, licensed under MPL2.

## Caveat Emptor

At the time of writing, the API is not considered to be stable. While we do our
best to prevent breakage, the core is in considerable flux and we do not
guarantee fit or function right now. The [conch
shell](https://github.com/joyent/conch-shell) is our current stable interface.

## Installation

### Operating System Support

We currently support SmartOS 17.4 and FreeBSD 11.2. Being a Perl app, the API
should run most anywhere but the code is only actively tested on SmartOS and
FreeBSD.

### Perl Support

The API is only certified to run against Perl 5.26.

### Setup

Conch uses [`carton`](https://metacpan.org/pod/Carton) to manage Perl
dependencies

Below is a list of useful Make commands that can be used to build and run the
project. All of these should be run in the top level directory.

* `make run` -- Build the project and run it
* `make test` -- Run tests
* `make migrate-db` -- Run database migrations

#### Needed Packages

* PostgreSQL 9.6
* Git
* Perl, 5.26 or above
* A compiler suite that is supported by Perl

#### Configuration

Copy `conch.conf.dist` to `conch.conf`, modifying for any local parameters,
including database connectivity information.

### Starting Conch

* `make run`

## Licensing

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.


