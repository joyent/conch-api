# Conch::Route::Organization

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Organization.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Organization.pm)

## METHODS

### routes

Sets up the routes for /organization.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /organization`

- Controller/Action: ["get\_all" in Conch::Controller::Organization](../modules/Conch%3A%3AController%3A%3AOrganization#get_all)
- Response: [response.json#/$defs/Organizations](../json-schema/response.json#/$defs/Organizations)

### `POST /organization`

- Requires system admin authorization
- Controller/Action: ["create" in Conch::Controller::Organization](../modules/Conch%3A%3AController%3A%3AOrganization#create)
- Request: [request.json#/$defs/OrganizationCreate](../json-schema/request.json#/$defs/OrganizationCreate)
- Response: `201 Created`, plus Location header

### `GET /organization/:organization_id_or_name`

- Requires system admin authorization or the admin role on the organization
- Controller/Action: ["get" in Conch::Controller::Organization](../modules/Conch%3A%3AController%3A%3AOrganization#get)
- Response: [response.json#/$defs/Organization](../json-schema/response.json#/$defs/Organization)

### `POST /organization/:organization_id_or_name`

- Requires system admin authorization or the admin role on the organization
- Controller/Action: ["update" in Conch::Controller::Organization](../modules/Conch%3A%3AController%3A%3AOrganization#update)
- Request: [request.json#/$defs/OrganizationUpdate](../json-schema/request.json#/$defs/OrganizationUpdate)
- Response: `204 No Content`, plus Location header

### `DELETE /organization/:organization_id_or_name`

- Requires system admin authorization
- Controller/Action: ["delete" in Conch::Controller::Organization](../modules/Conch%3A%3AController%3A%3AOrganization#delete)
- Response: `204 No Content`

### `POST /organization/:organization_id_or_name/user?send_mail=<1|0`>

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user.

- Requires system admin authorization or the admin role on the organization
- Controller/Action: ["add\_user" in Conch::Controller::Organization](../modules/Conch%3A%3AController%3A%3AOrganization#add_user)
- Request: [request.json#/$defs/OrganizationAddUser](../json-schema/request.json#/$defs/OrganizationAddUser)
- Response: `204 No Content`

### `DELETE /organization/:organization_id_or_name/user/#target_user_id_or_email?send_mail=<1|0`>

Takes one optional query parameter `send_mail=<1|0>` (defaults to 1) to send
an email to the user.

- Requires system admin authorization or the admin role on the organization
- Controller/Action: ["remove\_user" in Conch::Controller::Organization](../modules/Conch%3A%3AController%3A%3AOrganization#remove_user)
- Response: `204 No Content`

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
