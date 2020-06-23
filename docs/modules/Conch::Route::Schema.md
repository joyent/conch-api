# Conch::Route::Schema

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route/Schema.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route/Schema.pm)

## METHODS

### routes

Sets up the routes for /schema.

## ROUTE ENDPOINTS

### `GET /schema/query_params/:schema_name`

### `GET /schema/request/:schema_name`

### `GET /schema/response/:schema_name`

Returns the schema specified by type and name.

- Does not require authentication.
- Controller/Action: ["get" in Conch::Controller::Schema](../modules/Conch%3A%3AController%3A%3ASchema#get)
- Response: a JSON Schema ([http://json-schema.org/draft-07/schema#](http://json-schema.org/draft-07/schema#))

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
