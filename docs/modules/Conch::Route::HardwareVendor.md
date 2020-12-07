# Conch::Route::HardwareVendor

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/HardwareVendor.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/HardwareVendor.pm)

## METHODS

### routes

Sets up the routes for /hardware\_vendor.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /hardware_vendor`

- Controller/Action: ["get\_all" in Conch::Controller::HardwareVendor](../modules/Conch%3A%3AController%3A%3AHardwareVendor#get_all)
- Response: [response.json#/$defs/HardwareVendors](../json-schema/response.json#/$defs/HardwareVendors)

### `GET /hardware_vendor/:hardware_vendor_id_or_name`

- Controller/Action: ["get\_one" in Conch::Controller::HardwareVendor](../modules/Conch%3A%3AController%3A%3AHardwareVendor#get_one)
- Response: [response.json#/$defs/HardwareVendor](../json-schema/response.json#/$defs/HardwareVendor)

### `DELETE /hardware_vendor/:hardware_vendor_id_or_name`

- Requires system admin authorization
- Controller/Action: ["delete" in Conch::Controller::HardwareVendor](../modules/Conch%3A%3AController%3A%3AHardwareVendor#delete)
- Response: `204 No Content`

### `POST /hardware_vendor/:hardware_vendor_name`

- Requires system admin authorization
- Controller/Action: ["create" in Conch::Controller::HardwareVendor](../modules/Conch%3A%3AController%3A%3AHardwareVendor#create)
- Request: [request.json#/$defs/Null](../json-schema/request.json#/$defs/Null)
- Response: `201 Created`, plus Location header

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
