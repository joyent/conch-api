# Conch::Route::Schema

## METHODS

### routes

Sets up the routes for /schema.

## ROUTE ENDPOINTS

### `GET /schema/query_params/:schema_name`

### `GET /schema/request/:schema_name`

### `GET /schema/response/:schema_name`

Returns the schema specified by type and name.

- Does not require authentication.
- Response: a JSON-Schema ([http://json-schema.org/draft-07/schema](http://json-schema.org/draft-07/schema))

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
