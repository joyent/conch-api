# Conch::Controller::Build

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/Build.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/Build.pm)

## METHODS

### get\_all

If the user is a system admin, retrieve a list of all builds in the database; otherwise,
limits the list to those build of which the user is a member.

Response uses the Builds json schema.

### create

Creates a build.

Requires the user to be a system admin.

### find\_build

Chainable action that uses the `build_id_or_name` value provided in the stash (usually via the
request URL) to look up a build, and stashes the query to get to it in `build_rs`.

If `require_role` is provided, it is used as the minimum required role for the user to
continue; otherwise the user must have the 'admin' role.

### get

Get the details of a single build.
Requires the 'read-only' role on the build.

Response uses the Build json schema.

### update

Modifies a build attribute: one or more of name, description, started, completed.
Requires the 'admin' role on the build.

### get\_users

Get a list of user members of the current build. (Does not include users who can access the
build via an organization.)

Requires the 'admin' role on the build.

Response uses the BuildUsers json schema.

### add\_user

Adds a user to the current build, or upgrades an existing role entry to access the build.
Requires the 'admin' role on the build.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to the user and to all build admins.

This endpoint is nearly identical to ["add\_user" in Conch::Controller::Organization](../modules/Conch%3A%3AController%3A%3AOrganization#add_user).

### remove\_user

Removes the indicated user from the build.
Requires the 'admin' role on the build.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to the user and to all build admins.

This endpoint is nearly identical to ["remove\_user" in Conch::Controller::Organization](../modules/Conch%3A%3AController%3A%3AOrganization#remove_user).

### get\_organizations

Get a list of organization members of the current build.
Requires the 'admin' role on the build.

Response uses the BuildOrganizations json schema.

### add\_organization

Adds a organization to the current build, or upgrades an existing role entry to access the
build.
Requires the 'admin' role on the build.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to all organization members and all build admins.

### remove\_organization

Removes the indicated organization from the build.
Requires the 'admin' role on the build.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an email
to all organization members and to all build admins.

### find\_devices

Chainable action that stashes the query to get to all devices in `build_devices_rs`.

If `phase_earlier_than` is provided (defaulting to `production`), location data is omitted
for devices in the provided phase (or later) (and build racks are not used to find such devices
for such phases).

### get\_devices

Get the devices in this build. (Does not includes devices located in rack(s) in this build if
the devices themselves are in other builds.)

Requires the 'read-only' role on the build.

Supports these query parameters to constrain results (which are ANDed together for the search,
not ORed):

```
health=<value>      only devices with health matching the provided value
    (can be used more than once to search for ANY of the specified health values)
active_minutes=X    only devices last seen (via a report relay) within X minutes
ids_only=1          only return device ids, not full data
serials_only=1      only return device serial numbers, not full data
```

Response uses the Devices json schema, or DeviceIds iff `ids_only=1`, or DeviceSerials iff
`serials_only=1`.

### get\_pxe\_devices

Response uses the DevicePXEs json schema.

### create\_and\_add\_devices

Adds the specified device(s) to the build (removing them from their previous builds). The
device is created if necessary with all data provided (or updated with the data if it already
exists, so the endpoint is idempotent).

Requires the 'read/write' role on the build and on existing device(s).

### add\_device

Adds the specified device to the build (removing it from its previous build).

Requires the 'read/write' role on the build and on the device.

### remove\_device

Removes the specified device from the build (if it is **directly** in the build, not via a rack).

Requires the 'read/write' role on the build.

### get\_racks

Get the racks in this build.
Requires the 'read-only' role on the build.

Response uses the Racks json schema.

### add\_rack

Adds the specified rack to the build (removing it from its previous build).

Requires the 'read/write' role on the build and on the rack.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
