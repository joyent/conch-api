# Conch::Route::JSONSchema

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/JSONSchema.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/JSONSchema.pm)

## METHODS

### unsecured\_routes

Sets up the routes for /json\_schema that do not require authentication.

## ROUTE ENDPOINTS

### `GET /json_schema/query_params/:json_schema_name`

### `GET /json_schema/request/:json_schema_name`

### `GET /json_schema/response/:json_schema_name`

### `GET /json_schema/common/:json_schema_name`

### `GET /json_schema/device_report/:json_schema_name`

Returns the JSON Schema document specified by type and name, used for validating endpoint
requests and responses.

- Does not require authentication.
- Controller/Action: ["get" in Conch::Controller::JSONSchema](../modules/Conch%3A%3AController%3A%3AJSONSchema#get)
- Response: a JSON Schema ([response.json#/$defs/JSONSchemaOnDisk](../json-schema/response.json#/$defs/JSONSchemaOnDisk)) (Content-Type is
`application/schema+json`).

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
