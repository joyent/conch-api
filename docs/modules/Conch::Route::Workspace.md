# NAME

Conch::Route::Workspace

# METHODS

## routes

Sets up the routes for /workspace.

Note that in all routes using `:workspace_id_or_name`, the stash for `workspace_id` will be
populated, as well as `workspace_name` if the identifier was not a UUID.

Unless otherwise noted, all routes require authentication.

### `GET /workspace`

- Response: response.yaml#/WorkspacesAndRoles

### `GET /workspace/:workspace_id_or_name`

- Response: response.yaml#/WorkspaceAndRole

### `GET /workspace/:workspace_id_or_name/child`

- Response: response.yaml#/WorkspacesAndRoles

### `POST /workspace/:workspace_id_or_name/child`

- Requires Workspace Admin Authentication
- Request: request.yaml#/WorkspaceCreate
- Response: response.yaml#/WorkspaceAndRole

### `GET /workspace/:workspace_id_or_name/device`

Accepts the following optional query parameters:

- `graduated=<T|F>` show only devices where the `graduated` attribute is set/not-set
- `validated=<T|F>` show only devices where the `validated` attribute is set/not-set
- `health=<value>` show only devices with the health matching the provided value (case-insensitive)
- `active=t` show only devices which have reported within the last 5 minutes (this is different from all active devices)
- `ids_only=t` only return device IDs, not full device details

- Response: response.yaml#/Devices

### `GET /workspace/:workspace_id_or_name/device/pxe`

- Response: response.yaml#/WorkspaceDevicePXEs

### `GET /workspace/:workspace_id_or_name/rack`

- Response: response.yaml#/WorkspaceRackSummary

### `POST /workspace/:workspace_id_or_name/rack`

- Request: request.yaml#/WorkspaceAddRack
- Response: Redirect to the workspace rack

### `GET /workspace/:workspace_id_or_name/rack/:rack_id`

If the Accepts header specifies `text/csv` it will return a CSV document.

- Response: response.yaml#/WorkspaceRack

### `DELETE /workspace/:workspace_id_or_name/rack/:rack_id`

- Requires Workspace Admin Authentication
- Response: `204 NO CONTENT`

### `GET /workspace/:workspace_id_or_name/relay`

Takes one query optional parameter,  `active_within=X` to constrain results to
those updated with in the last `X` minutes.

- Response: response.yaml#/WorkspaceRelays

### `GET /workspace/:workspace_id_or_name/relay/:relay_id/device`

- Response: response.yaml#/Devices

### `GET /workspace/:workspace_id_or_name/user`

- Response: response.yaml#/WorkspaceUsers

### `POST /workspace/:workspace_id_or_name/user?send_mail=<1|0>`

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user

- Requires Workspace Admin Authentication
- Request: request.yaml#/WorkspaceAddUser
- Response: response.yaml#/WorkspaceAndRole

### `DELETE /workspace/:workspace_id_or_name/user/:target_user_id_or_email?send_mail=<1|0>`

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user

- Requires Workspace Admin Authentication
- Returns `204 NO CONTENT`

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
