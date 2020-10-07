# passwd - change a user's password

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Command/passwd.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Command/passwd.pm)

## SYNOPSIS

```
bin/conch passwd [--id <user_id>] [--email <email>] [--password <password>]

--id        The user's id.
--email     The user's email address. required, if id is not provided.
--password  The user's new password. If not provided, one will be randomly generated and echoed.

--help      print usage message and exit
```

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
