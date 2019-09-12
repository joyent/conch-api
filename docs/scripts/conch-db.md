# NAME

conch-db - commands to administrate a database

# SYNOPSIS

```
bin/conch-db [subcommand subcommand...] [-hnv] [long options...] [arguments]

initialize               initialize a new Conch database and its tables
create-validations       create validation plans for the Conch application
create-global-workspace  create the GLOBAL workspace
create-admin-user        create a user with admin privileges
migrate                  run outstanding migrations on a Conch database (no effect with 'all')
apply-dump-migration [n] generate new DBIC result classes, schema.sql after applying a migration(s)
all                      alias for initialize create-validations create-admin-user

The environment variables POSTGRES_DB, POSTGRES_HOST, POSTGRES_USER and POSTGRES_PASSWORD are
used if set. Otherwise, the config file will be used to find database credentials.

    -h --help       print usage message and exit
    -n --dry-run    use a test database instead of credentials you provide
    -v --verbose    print the queries that are executed

    --config STR    configuration file
                    (default value: conch.conf)
    --username STR  the new admin user's name
                    (default value: admin)
    --email STR     the new admin user's email address (required for
                    create-admin-user)
    --password STR  the new admin user's password (or one will be
                    randomly generated)
```

# DESCRIPTION

Work with the Conch database. Run `bin/conch-db --help` for a list of options.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
