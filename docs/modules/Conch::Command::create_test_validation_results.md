# create\_test\_validation\_results - create new-style validation\_result entries for testing

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Command/create_test_validation_results.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Command/create_test_validation_results.pm)

## SYNOPSIS

```
bin/conch create_test_validation_results [-de] [long options...]

  -n --dry-run            dry-run (no changes are made)
  --help                  print usage message and exit

  -d STR --device STR     the device serial number to use for the results
  -e STR --email STR      the creation user's email address
  --[no-]rvs --[no-]reuse-validation-state
                          use an existing validation_state (otherwise, create a new one)
```

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
