# Conch::Route::JSONSchema

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/JSONSchema.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/JSONSchema.pm)

## METHODS

### unsecured\_routes

Sets up the routes for /json\_schema that do not require authentication.

### secured\_routes

Sets up the routes for /json\_schema that require authentication.

## ROUTE ENDPOINTS

### `GET /json_schema/query_params/:json_schema_name`

### `GET /json_schema/request/:json_schema_name`

### `GET /json_schema/response/:json_schema_name`

### `GET /json_schema/common/:json_schema_name`

### `GET /json_schema/device_report/:json_schema_name`

Returns the JSON Schema document specified by type and name, used for validating endpoint
requests and responses.

- Does not require authentication.
- Controller/Action: ["get\_from\_disk" in Conch::Controller::JSONSchema](../modules/Conch%3A%3AController%3A%3AJSONSchema#get_from_disk)
- Response: a JSON Schema ([response.json#/$defs/JSONSchemaOnDisk](../json-schema/response.json#/$defs/JSONSchemaOnDisk)) (Content-Type is
`application/schema+json`).

### `POST /json_schema/:json_schema_type/:json_schema_name`

Stores a new JSON Schema in the database. Unresolvable `$ref`s are not permitted.

- Controller/Action: ["create" in Conch::Controller::JSONSchema](../modules/Conch%3A%3AController%3A%3AJSONSchema#create)
- Request: [request.json#/$defs/JSONSchema](../json-schema/request.json#/$defs/JSONSchema) (Content-Type is expected to be
`application/schema+json`).
- Response: `201 Created`, plus Location header

### `GET /json_schema/:json_schema_id`

### `GET /json_schema/:json_schema_type/:json_schema_name/:json_schema_version`

### `GET /json_schema/:json_schema_type/:json_schema_name/latest`

Fetches the referenced JSON Schema document.

- Controller/Action: ["get\_single" in Conch::Controller::JSONSchema](../modules/Conch%3A%3AController%3A%3AJSONSchema#get_single)
- Response: [response.json#/$defs/JSONSchema](../json-schema/response.json#/$defs/JSONSchema) (Content-Type is `application/schema+json`).

### `DELETE /json_schema/:json_schema_id`

Deactivates the database entry for a single JSON Schema, rendering it unusable.
This operation is not permitted until all references from other documents have been removed,
exception of references using `.../latest` which will now resolve to a different document
(and internal references will be re-verified).

If this JSON Schema was the latest of its series (`/json_schema/foo/bar/latest`), then that
`.../latest` link will now resolve to an earlier version in the series.

- Requires system admin authorization, if not the user who uploaded the document
- Controller/Action: ["delete" in Conch::Controller::JSONSchema](../modules/Conch%3A%3AController%3A%3AJSONSchema#delete)
- Response: `204 No Content`

### `GET /json_schema/:json_schema_type`

Gets meta information about all JSON Schemas in a particular type series.

- Controller/Action: ["get\_metadata" in Conch::Controller::JSONSchema](../modules/Conch%3A%3AController%3A%3AJSONSchema#get_metadata)
- Response: [response.json#/$defs/JSONSchemaDescriptions](../json-schema/response.json#/$defs/JSONSchemaDescriptions)

### `GET /json_schema/:json_schema_type/:json_schema_name`

Gets meta information about all JSON Schemas in a particular type and name series.

- Controller/Action: ["get\_metadata" in Conch::Controller::JSONSchema](../modules/Conch%3A%3AController%3A%3AJSONSchema#get_metadata)
- Response: [response.json#/$defs/JSONSchemaDescriptions](../json-schema/response.json#/$defs/JSONSchemaDescriptions)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
