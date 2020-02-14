# Conch::Controller::JSONSchema

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/JSONSchema.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/JSONSchema.pm)

## METHODS

### get\_from\_disk

Get a query parameters, request, response, common or device\_report JSON Schema (from
[query_params.json](../json-schema/query_params.json), [request.json](../json-schema/request.json), [response.json](../json-schema/response.json), [common.json](../json-schema/common.json), or [device_report.json](../json-schema/device_report.json),
respectively). Bundles all the referenced definitions together in the returned body response.

### create

Stores a new JSON Schema in the database.

The type names used in ["get\_from\_disk"](#get_from_disk) (`query_params`, `request`, `response`, `common`,
`device_report`) cannot be used.

The `$id`, `$anchor`, `definitions` and `dependencies` keywords are prohibited anywhere in the
document. `description` is required at the top level of the document.

### find\_json\_schema

Chainable action that uses the `json_schema_id`, `json_schema_type`, `json_schema_name`, and
`json_schema_version` values provided in the stash (usually via the request URL) to look up a
JSON Schema, and stashes a simplified query (by `id`) to get to it in `json_schema_rs`, and
the id itself in `json_schema_id`.

### get\_single

Gets a single JSON Schema specification document.

### delete

Deactivates the database entry for a single JSON Schema, rendering it unusable. This operation
is not permitted until all references from other documents have been removed, with the
exception of references using `.../latest` which will now resolve to a different document (and
paths within that document will be re-verified).

If this JSON Schema was the latest of its series (`/json_schema/foo/bar/latest`), then that
`.../latest` link will now resolve to an earlier version in the series.

### get\_metadata

Gets meta information about all JSON Schemas in a particular type and name series.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
