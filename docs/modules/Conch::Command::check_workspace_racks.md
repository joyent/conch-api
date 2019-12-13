# NAME

check\_workspace\_racks - Utility to check all workspace\_rack entries are correct and complete

# SYNOPSIS

```
bin/conch check_workspace_racks [long options...]
    -n --dry-run    dry-run (no changes are made)
    -v --verbose    verbose

    --help          print usage message and exit
```

# DESCRIPTION

For all racks, checks that necessary `workspace_rack` rows exist (for every parent to the
workspace referenced by existing `workspace_rack` entries). Missing rows are populated,
if `--dry-run` not provided. Errors are identified, if `--verbose` is provided.

# EXIT CODE

Returns the number of errors found.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
