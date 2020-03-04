# Conch::Route::Workspace

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route/Workspace.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route/Workspace.pm)

## METHODS

### routes

Sets up the routes for /workspace.

Note that in all routes using `:workspace_id_or_name`, the stash for `workspace_id` will be
populated, as well as `workspace_name` if the identifier was not a UUID.

All `/workspace` routes are deprecated and will be removed in Conch API v3.1.

## ROUTE ENDPOINTS

All routes require authentication.

Users will require access to the workspace (or one of its ancestors) at a minimum
[role](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserWorkspaceRole#role), as indicated.

### `GET /workspace`

- User requires the read-only role
- Response: [response.json#/definitions/WorkspacesAndRoles](../json-schema/response.json#/definitions/WorkspacesAndRoles)

### `GET /workspace/:workspace_id_or_name`

- User requires the read-only role
- Response: [response.json#/definitions/WorkspaceAndRole](../json-schema/response.json#/definitions/WorkspaceAndRole)

### `GET /workspace/:workspace_id_or_name/child`

- User requires the read-only role
- Response: [response.json#/definitions/WorkspacesAndRoles](../json-schema/response.json#/definitions/WorkspacesAndRoles)

### `POST /workspace/:workspace_id_or_name/child?send_mail=<1|0>`

Takes one optional query parameter `send_mail=<1|0>` (defaults to `1`) to send
an email to the parent workspace admins.

- User requires the read/write role
- Request: [request.json#/definitions/WorkspaceCreate](../json-schema/request.json#/definitions/WorkspaceCreate)
- Response: [response.json#/definitions/WorkspaceAndRole](../json-schema/response.json#/definitions/WorkspaceAndRole)

### `GET /workspace/:workspace_id_or_name/device`

Accepts the following optional query parameters:

- `validated=<1|0>` show only devices where the `validated` attribute is set/not-set
- `health=:value` show only devices with the health matching the provided value
- `active_minutes=:X` show only devices which have reported within the last X minutes (this is different from all active devices)
- `ids_only=1` only return device IDs, not full device details

- User requires the read-only role
- Response: one of [response.json#/definitions/Devices](../json-schema/response.json#/definitions/Devices), [response.json#/definitions/DeviceIds](../json-schema/response.json#/definitions/DeviceIds) or [response.json#/definitions/DeviceSerials](../json-schema/response.json#/definitions/DeviceSerials)

### `GET /workspace/:workspace_id_or_name/device/pxe`

- User requires the read-only role
- Response: [response.json#/definitions/WorkspaceDevicePXEs](../json-schema/response.json#/definitions/WorkspaceDevicePXEs)

### `GET /workspace/:workspace_id_or_name/rack`

- User requires the read-only role
- Response: [response.json#/definitions/WorkspaceRackSummary](../json-schema/response.json#/definitions/WorkspaceRackSummary)

### `POST /workspace/:workspace_id_or_name/rack`

- User requires the admin role
- Request: [request.json#/definitions/WorkspaceAddRack](../json-schema/request.json#/definitions/WorkspaceAddRack)
- Response: Redirect to the workspace's racks

### `DELETE /workspace/:workspace_id_or_name/rack/:rack_id_or_name`

- User requires the admin role
- Response: `204 No Content`

### `GET /workspace/:workspace_id_or_name/relay`

Takes one query optional parameter, `?active_minutes=X` to constrain results to
those updated with in the last `X` minutes.

- User requires the read-only role
- Response: [response.json#/definitions/WorkspaceRelays](../json-schema/response.json#/definitions/WorkspaceRelays)

### `GET /workspace/:workspace_id_or_name/relay/:relay_id/device`

- User requires the read-only role
- Response: [response.json#/definitions/Devices](../json-schema/response.json#/definitions/Devices)

### `GET /workspace/:workspace_id_or_name/user`

- User requires the admin role
- Response: [response.json#/definitions/WorkspaceUsers](../json-schema/response.json#/definitions/WorkspaceUsers)

### `POST /workspace/:workspace_id_or_name/user?send_mail=<1|0>`

Takes one optional query parameter `send_mail=<1|0>` (defaults to `1`) to send
an email to the user and workspace admins.

- User requires the admin role
- Request: [request.json#/definitions/WorkspaceAddUser](../json-schema/request.json#/definitions/WorkspaceAddUser)
- Response: `204 No Content`

### `DELETE /workspace/:workspace_id_or_name/user/:target_user_id_or_email?send_mail=<1|0>`

Takes one optional query parameter `send_mail=<1|0>` (defaults to `1`) to send
an email to the user and workspace admins.

- User requires the admin role
- Response: `204 No Content`

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
