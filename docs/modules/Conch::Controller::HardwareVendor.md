# Conch::Controller::HardwareVendor

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/HardwareVendor.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/HardwareVendor.pm)

## METHODS

### find\_hardware\_vendor

Chainable action that uses the `hardware_vendor_id_or_name` value provided in the stash
(usually via the request URL) to look up a hardware vendor, and stashes the result in
`hardware_vendor`.

### get\_all

Retrieves all active hardware vendors.

Response uses the HardwareVendors json schema.

### get\_one

Gets one (active) hardware vendor.

Response uses the HardwareVendor json schema.

### create

### delete

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
