# NAME

Conch::DB::ResultSet::Device

# DESCRIPTION

Interface to queries involving devices.

# METHODS

## user\_has\_permission

Checks that the provided user\_id has (at least) the specified permission in at least one
workspace associated with the specified device(s), including parent workspaces.

## devices\_without\_location

Restrict results to those that do not have a registered location.

## latest\_device\_report

Returns a resultset that finds the most recent device report matching the device(s). This is
not a window function, so only one report is returned for all matching devices, not one report
per device! (We probably never need to do the latter. \*)

\* but if we did, you'd want something like:

```perl
$self->search(undef, {
    '+columns' => {
        $col => $self->correlate('device_reports')
            ->columns($col)
            ->order_by({ -desc => 'device_reports.created' })
            ->rows(1)
            ->as_query
    },
});
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
