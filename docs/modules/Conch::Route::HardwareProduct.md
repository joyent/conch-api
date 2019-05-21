# NAME

Conch::Route::HardwareProduct

# METHODS

## routes

Sets up the routes for /hardware\_product:

Unless otherwise noted, all routes require authentication.

### `GET /hardware_product`

- Response: response.yaml#/HardwareProducts

### `POST /hardware_product`

- Requires System Admin Authentication
- Request: input.yaml#/HardwareProductCreate
- Response: Redirect to the created hardware product

### `GET /hardware_product/:identifier`

- Response: response.yaml#/HardwareProduct

### `POST /hardware_product/:identifier`

- Requires System Admin Authentication
- Request: input.yaml#/HardwareProductUpdate
- Response: Redirect to the updated hardware product

### `DELETE /hardware_product/:identifier`

- Requires System Admin Authentication
- Response: `204 NO CONTENT`

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
