# Conch API Server

Conch helps you build and manage datacenters.

Conch's goal is to provide an end-to-end solution for full datacenter resource
lifecycle: from design to initial power-on to end-of-life for all components of
all devices.

Conch is open source, licensed under MPL2.

[More documentation can be found here.](https://joyent.github.io/conch/)

## Caveat Emptor

The API is in a constant state of flux. Contact the development team before
attempting to use it directly.
The [conch shell](https://github.com/joyent/conch-shell) is our current stable interface.

## Installation

### Operating System Support

We currently support SmartOS 17.4 and Docker/Ubuntu. Being a Perl app, the API
should run most anywhere but the code is only actively tested on SmartOS and
Docker/Ubuntu.

### Perl Support

The API is only certified to run against Perl 5.26.

### Setup

Below is a list of useful Make commands that can be used to build and run the
project. All of these should be run in the top level directory.

* `make run` -- Build the project and run it
* `make test` -- Run tests
* `make migrate-db` -- Run database migrations

#### Needed Packages

* PostgreSQL 10
* Git
* Perl, 5.26 or above (e.g. via [perlbrew](https://perlbrew.pl/))
* [Carton](https://metacpan.org/dist/Carton)

#### Configuration

Copy `conch.conf.dist` to `conch.conf`, modifying for any local parameters,
including database connectivity information.

### Starting Conch

* `make run`

## Docker

### Images

For every release, the Joyent test infrastructure publishes a docker image to
hub.docker.com . These images are available at
https://hub.docker.com/r/joyentbuildops/conch-api/tags and it is wise to
consult the Github release page ( https://github.com/joyent/conch/releases ) to
determine if the release is a staging or production image.

The 'latest' image is not supported and is rebuilt manually and infrequently.
*Always* use a release tag.

### Compose

The most simple way to get going with the Conch API is to use Docker Compose.

#### First Run

Copy `conch.conf.dist` to `conch.conf`, modifying for any local parameters.
Specifically search for 'docker' in the comments. Ignore the database
parameters.


```
# Edit compose file for desired release
docker-compose up -d postgres # initialize the postgres database
docker-compose run --rm web bin/conch-db all --username conch --email conch@example.com --password kaewee3hipheem8BaiHoo6waed7pha
docker-compose run --rm web bin/conch-db create-global-workspace
docker-compose up -d
```

#### Upgrading

```
docker-compose down
# Edit compose file for desired release
docker-compose pull
docker-compose up -d postgres
docker-compose run --rm web bin/conch-db migrate
docker-compose up -d
```

There may be extra commands to run, depending on the specific release. In that
case, the upgrade will look something like:

```
docker-compose down
# Edit compose file for desired release
docker-compose pull
docker-compose up -d postgres
docker-compose run --rm web bin/conch-db migrate
docker-compose run --rm web bin/conch upgrade_release_225
docker-compose up -d
```


## Licensing

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at <http://mozilla.org/MPL/2.0/>.
