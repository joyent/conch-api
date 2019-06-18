# NAME

Conch::Route::HardwareVendor

# METHODS

## routes

Sets up the routes for /hardware\_vendor:

Unless otherwise noted, all routes require authentication.

### `GET /hardware_vendor`

- Response: response.yaml#/HardwareVendors

### `GET /hardware_vendor/:hardware_vendor_id_or_name`

- Response: response.yaml#/HardwareVendor

### `DELETE /hardware_vendor/:hardware_vendor_id_or_name`

- Response: `204 NO CONTENT`

### `POST /hardware_vendor/:hardware_vendor_name`

- Requires system admin authorization
- Response: Redirect to the created hardware vendor

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
