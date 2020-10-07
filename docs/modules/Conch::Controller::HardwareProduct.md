# Conch::Controller::HardwareProduct

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/HardwareProduct.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Controller/HardwareProduct.pm)

## METHODS

### get\_all

Get a list of all available hardware products.

Response uses the HardwareProducts json schema.

### find\_hardware\_product

Chainable action that uses the `hardware_product_id_or_other` value provided in the stash
(usually via the request URL) to look up a hardware\_product, and stashes the query to get to it
in `hardware_product_rs`.

Supported identifiers in path are: `id`, `sku`, `name`, and `alias`.

### get

Get the details of a single hardware product.

Response uses the HardwareProduct json schema.

### create

Creates a new hardware\_product.

### update

Updates an existing hardware\_product.

### delete

### set\_specification

Uses the URI query parameter `path` as a json pointer to determine the path within the
`specification` property to operate on. New data is written, and existing data is overwritten
without regard to type (so long as it conforms to the schema).

After the update operation, the `specification` property must validate against
[common.json#/definitions/HardwareProductSpecification](../json-schema/common.json#/definitions/HardwareProductSpecification).

### delete\_specification

Uses the URI query parameter `path` as a json pointer to determine the path within the
`specification` property to operate on. All of the data at the indicated path is deleted.

After the delete operation, the `specification` property must validate against
[common.json#/definitions/HardwareProductSpecification](../json-schema/common.json#/definitions/HardwareProductSpecification).

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
