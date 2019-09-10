# NAME

Conch::Route::HardwareProduct

# METHODS

## routes

Sets up the routes for /hardware\_product:

Unless otherwise noted, all routes require authentication.

### `GET /hardware_product`

- Response: [response.json#/definitions/HardwareProducts](../json-schema/response.json#/definitions/HardwareProducts)

### `POST /hardware_product`

- Requires system admin authorization
- Request: [request.json#/definitions/HardwareProductCreate](../json-schema/request.json#/definitions/HardwareProductCreate)
- Response: Redirect to the created hardware product

### `GET /hardware_product/:hardware_product_id`

### `GET /hardware_product/name=:hardware_product_name`

### `GET /hardware_product/alias=:hardware_product_alias`

### `GET /hardware_product/sku=:hardware_product_sku`

- Response: [response.json#/definitions/HardwareProduct](../json-schema/response.json#/definitions/HardwareProduct)

### `POST /hardware_product/:hardware_product_id`

### `POST /hardware_product/name=:hardware_product_name`

### `POST /hardware_product/alias=:hardware_product_alias`

### `POST /hardware_product/sku=:hardware_product_sku`

- Requires system admin authorization
- Request: [request.json#/definitions/HardwareProductUpdate](../json-schema/request.json#/definitions/HardwareProductUpdate)
- Response: Redirect to the updated hardware product

### `DELETE /hardware_product/:hardware_product_id`

### `DELETE /hardware_product/name=:hardware_product_name`

### `DELETE /hardware_product/alias=:hardware_product_alias`

### `DELETE /hardware_product/sku=:hardware_product_sku`

- Requires system admin authorization
- Response: `204 NO CONTENT`

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
