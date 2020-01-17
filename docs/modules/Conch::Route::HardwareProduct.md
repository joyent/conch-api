# NAME

Conch::Route::HardwareProduct

# METHODS

## routes

Sets up the routes for /hardware\_product.

# ROUTE ENDPOINTS

All routes require authentication.

## `GET /hardware_product`

- Response: [response.json#/definitions/HardwareProducts](../json-schema/response.json#/definitions/HardwareProducts)

## `POST /hardware_product`

- Requires system admin authorization
- Request: [request.json#/definitions/HardwareProductCreate](../json-schema/request.json#/definitions/HardwareProductCreate)
- Response: Redirect to the created hardware product

## `GET /hardware_product/:hardware_product_id_or_other`

Identifiers accepted: `id`, `sku`, `name` and `alias`.

- Response: [response.json#/definitions/HardwareProduct](../json-schema/response.json#/definitions/HardwareProduct)

## `POST /hardware_product/:hardware_product_id_or_other`

Identifiers accepted: `id`, `sku`, `name` and `alias`.

- Requires system admin authorization
- Request: [request.json#/definitions/HardwareProductUpdate](../json-schema/request.json#/definitions/HardwareProductUpdate)
- Response: Redirect to the updated hardware product

## `DELETE /hardware_product/:hardware_product_id_or_other`

Identifiers accepted: `id`, `sku`, `name` and `alias`.

- Requires system admin authorization
- Response: `204 NO CONTENT`

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
