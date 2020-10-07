# Conch::Route::HardwareProduct

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/HardwareProduct.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/HardwareProduct.pm)

## METHODS

### routes

Sets up the routes for /hardware\_product.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /hardware_product`

- Controller/Action: ["get\_all" in Conch::Controller::HardwareProduct](../modules/Conch%3A%3AController%3A%3AHardwareProduct#get_all)
- Response: [response.json#/definitions/HardwareProducts](../json-schema/response.json#/definitions/HardwareProducts)

### `POST /hardware_product`

- Requires system admin authorization
- Controller/Action: ["create" in Conch::Controller::HardwareProduct](../modules/Conch%3A%3AController%3A%3AHardwareProduct#create)
- Request: [request.json#/definitions/HardwareProductCreate](../json-schema/request.json#/definitions/HardwareProductCreate)
- Response: Redirect to the created hardware product

### `GET /hardware_product/:hardware_product_id_or_other`

Identifiers accepted: `id`, `sku`, `name` and `alias`.

- Controller/Action: ["get" in Conch::Controller::HardwareProduct](../modules/Conch%3A%3AController%3A%3AHardwareProduct#get)
- Response: [response.json#/definitions/HardwareProduct](../json-schema/response.json#/definitions/HardwareProduct)

### `POST /hardware_product/:hardware_product_id_or_other`

Updates the indicated hardware product.

Identifiers accepted: `id`, `sku`, `name` and `alias`.

- Requires system admin authorization
- Controller/Action: ["update" in Conch::Controller::HardwareProduct](../modules/Conch%3A%3AController%3A%3AHardwareProduct#update)
- Request: [request.json#/definitions/HardwareProductUpdate](../json-schema/request.json#/definitions/HardwareProductUpdate)
- Response: Redirect to the updated hardware product

### `DELETE /hardware_product/:hardware_product_id_or_other`

Deactivates the indicated hardware product, preventing it from being used. All devices using this
hardware must be switched to other hardware first.

Identifiers accepted: `id`, `sku`, `name` and `alias`.

- Requires system admin authorization
- Controller/Action: ["delete" in Conch::Controller::HardwareProduct](../modules/Conch%3A%3AController%3A%3AHardwareProduct#delete)
- Response: `204 No Content`

### `PUT /hardware_product/:hardware_product_id_or_other/specification?path=:path_to_data`

Sets a specific part of the json blob data in the `specification` field, treating the URI query
parameter `path` as the JSON pointer to the data to be added or modified. Existing data at the path
is overwritten without regard to type, so long as the JSON Schema is respected. For example, this
existing `specification` field and this request:

```
{
  "foo": { "bar": 123 },
  "x": { "y": [ 1, 2, 3 ] }
}

POST /hardware_product/:hardware_product_id_or_other/specification?path=/foo/bar/baz  { "hello":1 }
```

Results in this data in `specification`, changing the data type at node `/foo/bar`:

```
{
  "foo": { "bar": { "baz": { "hello": 1 } } },
  "x": { "y": [ 1, 2, 3 ] }
}
```

- Requires system admin authorization
- Controller/Action: ["set\_specification" in Conch::Controller::HardwareProduct](../modules/Conch%3A%3AController%3A%3AHardwareProduct#set_specification)
- Request: after the update operation, the `specification` property must validate against
[common.json#/definitions/HardwareProductSpecification](../json-schema/common.json#/definitions/HardwareProductSpecification).
- Response: `204 No Content`

### `DELETE /hardware_product/:hardware_product_id_or_other/specification?path=:path_to_data`

Deletes a specific part of the json blob data in the `specification` field, treating the URI query
parameter `path` as the JSON pointer to the data to be removed. All other properties in the json
blob are left untouched.

After the delete operation, the `specification` property must validate against
[common.json#/definitions/HardwareProductSpecification](../json-schema/common.json#/definitions/HardwareProductSpecification).

- Requires system admin authorization
- Controller/Action: ["delete\_specification" in Conch::Controller::HardwareProduct](../modules/Conch%3A%3AController%3A%3AHardwareProduct#delete_specification)
- Response: `204 No Content`

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
