# NAME

Conch::Controller::HardwareProduct

# METHODS

## list

Get a list of all available hardware products.

Response uses the HardwareProducts json schema.

## find\_hardware\_product

Chainable action that uses the `hardware_product_id` or `hardware_product_key` and
`hardware_product_value` values provided in the stash (usually via the request URL) to look up
a hardware\_product, and stashes the query to get to it in `hardware_product_rs`.

Supported keys are: `sku`, `name`, and `alias`.

## get

Get the details of a single hardware product.

Response uses the HardwareProduct json schema.

## create

Creates a new hardware\_product.

## update

Updates an existing hardware\_product.

## delete

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
