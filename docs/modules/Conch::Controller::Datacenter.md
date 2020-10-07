# Conch::Controller::Datacenter

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/Datacenter.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/Datacenter.pm)

## METHODS

### find\_datacenter

Chainable action that uses the `datacenter_id` value provided in the stash (usually via the
request URL) to look up a datacenter, and stashes the result in `datacenter`.

### get\_all

Get all datacenters.

Response uses the Datacenters json schema.

### get\_one

Get a single datacenter.

Response uses the Datacenter json schema.

### get\_rooms

Get all rooms for the given datacenter.

Response uses the DatacenterRoomsDetailed json schema.

### create

Create a new datacenter.

### update

Update an existing datacenter.

### delete

Permanently delete a datacenter.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
