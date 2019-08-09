# NAME

Conch::Route::Build

# METHODS

## routes

Sets up the routes for /build.

Unless otherwise noted, all routes require authentication.

### `GET /build`

- Response: response.yaml#/Builds

### `POST /build`

- Requires system admin authorization
- Request: request.yaml#/BuildCreate
- Response: Redirect to the build

### `GET /build/:build_id_or_name`

- Requires system admin authorization or the read-only role on the build
- Response: response.yaml#/Build

### `POST /build/:build_id_or_name`

- Requires system admin authorization or the admin role on the build
- Request: request.yaml#/BuildUpdate
- Response: Redirect to the build

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
