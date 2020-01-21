# create\_user - create a new user, optionally sending an email

## SYNOPSIS

```
  bin/conch create_user --email <email> --name <name> [--password <password>] [--send-email]

--email       The user's email address. Required.
--name        The user's name. Required.
--password    The user's temporary password. If not provided, one will be randomly generated.
--send-email   Send a welcome email to the user (defaults to true)

    --help    print usage message and exit
```

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
