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

### `GET /build/:build_id_or_name/user`

- Requires system admin authorization or the admin role on the build
- Response: response.yaml#/BuildUsers

### `POST /build/:build_id_or_name/user?send_mail=<1|0`>

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user.

- Requires system admin authorization or the admin role on the build
- Request: request.yaml#/BuildAddUser
- Response: `204 NO CONTENT`

### `DELETE /build/:build_id_or_name/user/#target_user_id_or_email?send_mail=<1|0`>

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user.

- Requires system admin authorization or the admin role on the build
- Returns `204 NO CONTENT`

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
