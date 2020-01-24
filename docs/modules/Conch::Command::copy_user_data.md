# copy\_user\_data - copy user data (user records and authentication tokens) between databases

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Command/copy_user_data.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Command/copy_user_data.pm)

## SYNOPSIS

```
bin/conch copy_user_data [long options...]

    --from        name of database to copy from (required)
    --to          name of database to copy to (required)
    -n --dry-run  dry-run (no changes are made)

    --help        print usage message and exit
```

## DESCRIPTION

Use this script after restoring a database backup to a separate database, before swapping it into place to go live. e.g.:

```perl
psql -U postgres --command="create database conch_prod_$(date '+%Y%m%d) owner conch"
pg_restore -U postgres -d conch_prod_$(date '+%Y%m%d') -j 3 -v /path/to/$(date '+%Y-%m-%d')T00:00:00Z; date

psql -U postgres --command="create database conch_staging_$(date '+%Y%m%d')_user_bak owner conch"
psql -U postgres conch_staging_$(date '+%Y%m%d')_user_bak --command="CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public"
pg_dump -U conch  --inserts -t user_account -t user_session_token conch | psql -U conch conch_staging_$(date '+%Y%m%d')_user_bak
carton exec bin/conch copy_user_data --from conch_staging_$(date '+%Y%m%d')_user_bak --to conch_prod_$(date '+%Y%m%d')

carton exec hypnotoad -s bin/conch
psql -U postgres --command="alter database conch rename to conch_staging_$(date '+%Y%m%d')_bak; alter database conch_prod_$(date '+%Y%m%d') rename to conch"
carton exec hypnotoad bin/conch
```

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
