# Conch API Server

Datacenter build and management service

# Setup

Conch uses [`carton`](https://metacpan.org/pod/Carton) to manage Perl
dependencies and `npm` for nodejs depdencies.  Both are required for building and
running the project.

Below is a list of useful Make commands that can be used to build and run the
project. All of these should be run in the top level directory.

* `make build` -- Install dependencies and build Perl and Javascript Source
* `make run` -- Build the project and run it
* `make watch` -- Continuously build and run the code, using [`entr`](http://entrproject.org).
* `make format` -- Auto-format source code
* `make test` -- Run tests
* `make migrate-db` -- Run database migrations

# API

The Conch API is documented at [here](https://conch.joyent.us/doc).

# Installation

## NOTE

Currently there is a bug in the `HTTP::XSCookie` module, making it non-portable
on illumos. Please use an LX zone over an OS zone.

## Linux install

```
# apt-get install -y build-essential git carton perl-doc postgresql-server-dev-9.5 \
   postgresql-client-common postgresql-client-9.5

# git clone git@github.com:joyent/conch.git
# cd conch

# carton install
Installing modules using /root/src/conch/cpanfile
...
208 distributions installed
Complete! Modules were installed into /root/src/conch/local

```

## Configuration

Copy `environments/development.yml.dist` to `environments/development.yml`.

Edit the database connection info in `environments/development.yml`:

```
plugins:
  DBIC:
    default:
      dsn: dbi:Pg:dbname=conch;host=1.2.3.4
      user: conch
      password: SECRET
      schema_class: Conch::Schema
```

# Starting Conch

```
# carton exec plackup -p 5000 bin/app.psgi
trace: switching to run mode 3 for Log::Report::Dispatcher::Callback, accept ALL
HTTP::Server::PSGI: Accepting connections at http://0:5000/
```
