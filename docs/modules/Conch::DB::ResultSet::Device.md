# Conch::DB::ResultSet::Device

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/Device.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/Device.pm)

## DESCRIPTION

Interface to queries involving devices.

## METHODS

### with\_user\_role

Constrains the resultset to those where the provided user\_id has (at least) the specified role
in at least one build associated with the specified device(s) (also taking into
consideration the rack location of the device(s) if its phase is early enough).

This is a nested query which searches all builds in the database, so only use
this query when its impact is outweighed by the impact of filtering a large resultset of
devices in the database. (That is, usually you should start with a single device and then
apply `$device_rs->user_has_role($user_id, $role)` to it.)

### user\_has\_role

Checks that the provided user\_id has (at least) the specified role in at least one
build associated with the specified device(s), also taking into consideration the rack location of
the device(s) if its phase is early enough.

Returns a boolean.

### devices\_without\_location

Restrict results to those that do not have a registered location.

### devices\_reported\_by\_user\_relay

Restrict results to those that have sent a device report proxied by a relay
registered using the provided user's credentials.

Note: this is not accurate if the relay is now registered to a different user than that which
sent the report.

### latest\_device\_report

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

### device\_settings\_as\_hash

Returns a hash of all (active) device settings for the specified device(s). (Will return
merged results when passed a resultset referencing multiple devices, which is probably not what
you want, so don't do that.)

### with\_device\_location

Modifies the resultset to add columns `rack_id`, `rack_name` (the full rack name including
room data) and `rack_unit_start`.

### with\_sku

Modifies the resultset to add the `sku` column.

### with\_build\_name

Modifies the resultset to add the `build_name` column.

### location\_data

Returns a resultset that provides location data ([response.json#/definitions/DeviceLocation](../json-schema/response.json#/definitions/DeviceLocation)),
optionally returned under a hash using the provided key name.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
