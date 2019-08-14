# NAME

Conch::DB::ResultSet::Device

# DESCRIPTION

Interface to queries involving devices.

# METHODS

## with\_user\_role

Constrains the resultset to those where the provided user\_id has (at least) the specified role
in at least one workspace associated with the specified device(s), including parent workspaces.

## user\_has\_role

Checks that the provided user\_id has (at least) the specified role in at least one
workspace associated with the specified device(s), including parent workspaces.

## devices\_without\_location

Restrict results to those that do not have a registered location.

## devices\_reported\_by\_user\_relay

Restrict results to those that have sent a device report proxied by a relay
registered using the provided user's credentials.

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

## device\_settings\_as\_hash

Returns a hash of all (active) device settings for the specified device(s).  (Will return
merged results when passed a resultset referencing multiple devices, which is probably not what
you want, so don't do that.)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
