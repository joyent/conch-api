# Conch API Server

# Installation

## NOTE

Currently there is a bug in the `HTTP::XSCookie` module, making it non-portable
on illumos. Please use an LX zone over an OS zone.

## Linux install

```
# apt-get install -y build-essential git carton perl-doc postgresql-server-dev-9.5 \
   postgresql-client-common postgresql-client-9.5

# git clone git@github.com:joyent/conch.git
# cd conch/Conch

# carton install
Installing modules using /root/src/conch/Conch/cpanfile
...
208 distributions installed
Complete! Modules were installed into /root/src/conch/Conch/local

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
