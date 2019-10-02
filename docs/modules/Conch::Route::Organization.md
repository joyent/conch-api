# NAME

Conch::Route::Organization

# METHODS

## routes

Sets up the routes for /organization.

Unless otherwise noted, all routes require authentication.

### `GET /organization`

- Response: [response.json#/definitions/Organizations](../json-schema/response.json#/definitions/Organizations)

### `POST /organization`

- Requires system admin authorization
- Request: [request.json#/definitions/OrganizationCreate](../json-schema/request.json#/definitions/OrganizationCreate)
- Response: Redirect to the organization

### `GET /organization/:organization_id_or_name`

- Requires system admin authorization or the admin role on the organization
- Response: [response.json#/definitions/Organization](../json-schema/response.json#/definitions/Organization)

### `DELETE /organization/:organization_id_or_name`

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `POST /organization/:organization_id_or_name/user?send_mail=<1|0`>

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user.

- Requires system admin authorization or the admin role on the organization
- Request: [request.json#/definitions/OrganizationAddUser](../json-schema/request.json#/definitions/OrganizationAddUser)
- Response: `204 NO CONTENT`

### `DELETE /organization/:organization_id_or_name/user/#target_user_id_or_email?send_mail=<1|0`>

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user.

- Requires system admin authorization or the admin role on the organization
- Response: `204 NO CONTENT`

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
