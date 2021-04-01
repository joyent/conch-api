# NOTICE

The Conch API has reached its end of life. _So long and thanks for all the fish._

# Conch API Server

Conch helps you build and manage datacenters.

Conch's goal is to provide an end-to-end solution for full datacenter resource
lifecycle: from design to initial power-on to end-of-life for all components of
all devices.

Conch is open source, licensed under MPL2.

[More documentation can be found here.](https://joyent.github.io/conch-api/)

This repository only encompasses the API server. Repositories for other parts of
the Conch ecosystem can be found here (some repositories may be private which
will require you to request access):

* [kosh, the command line interface](https://github.com/joyent/kosh)
* [web UI](https://github.com/joyent/conch-ui)
* [build infrastructure](https://github.com/joyent/buildops-infra)
* [conch-relay, which sends device reports](https://github.com/joyent/conch-relay)
* [conch-relay-go, ""](https://github.com/joyent/conch-relay-go)
* [conch-reporter, ""](https://github.com/joyent/conch-reporter)
* [conch-livesys, which configures live systems and creates device reports](https://github.com/joyent/conch-livesys)

## Caveat Emptor

The API is in a constant state of flux. Contact the development team before
attempting to use it directly.
The [conch shell](https://github.com/joyent/kosh)
and the [Web UI](https://github.com/joyent/conch-ui) are our current stable interfaces.

## Installation

### Operating System Support

We currently support Docker/Ubuntu. Being a Perl app, the API
should run nearly anywhere but the code is only actively tested on macOS and
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

* PostgreSQL 10.14
* Git
* Perl, 5.26 or above (e.g. via [perlbrew](https://perlbrew.pl/))
* [Carton](https://metacpan.org/dist/Carton)

#### Configuration

Copy `conch.conf.dist` to `conch.conf`, modifying for any local parameters,
including database connectivity information.

### Starting Conch

* `make run`

## Creating Local Credentials

First, you need to get a login token into the local database. We can do this by leveraging the
knowledge that an encrypted password entry of `''` will match against all supplied inputs:

  $ psql -U conch conch --command="insert into user_account (name, password, email) values ('me', '', 'your_email@joyent.com')"

Now, we use this email and password to generate a login token:

  make run
  curl -i -H'Content-Type: application/json' --url http://127.0.0.1:5001/login -d '{"email":"your_email@joyent.com","password":"anything"}'

You will see output like this:

  {"jwt_token":"eyJInR5cCI6Iwhargarbl.eyJl9pZCI6ImM1MGYwhargarbl.WV3uJEvg0bqInI9pEtl04ZZ8ECN4yQOSmehello"}

Save that token somewhere, such as in an environment variable or a file, for use in future API calls. You will include it in the "Authorization" header, for example:

  curl -i --url https://staging.conch.joyent.us/user/me --header "Authorization: Bearer eyJInR5cCI6Iwhargarbl.eyJl9pZCI6ImM1MGYwhargarbl.WV3uJEvg0bqInI9pEtl04ZZ8ECN4yQOSmehello"

## Docker

### Compose

The most simple way to get going with the Conch API is to use Docker Compose.

#### Build

First, build the image locally using `docker/builder.sh`

#### First Run

Copy `conch.conf.dist` to `conch.conf`, modifying for any local parameters.
Specifically search for 'docker' in the comments. Ignore the database
parameters.


```
# Edit compose file for desired release
docker-compose up -d postgres # initialize the postgres database
docker-compose run --rm web bin/conch-db all --username conch --email conch@example.com --password kaewee3hipheem8BaiHoo6waed7pha
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


## Licensing

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at <https://www.mozilla.org/en-US/MPL/2.0/>.
