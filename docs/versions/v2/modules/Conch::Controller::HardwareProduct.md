# NAME

Conch::Controller::HardwareProduct

# METHODS

## list

Get a list of all available hardware products.

Response uses the HardwareProducts json schema.

## find\_hardware\_product

Chainable action that looks up the object by id, sku, name or alias depending on the url
pattern, stashing the query to get to it in `hardware_product_rs`.

## get

Get the details of a single hardware product.

Response uses the HardwareProduct json schema.

## create

Creates a new hardware\_product, and possibly also a hardware\_product\_profile.

## update

Updates an existing hardware\_product, possibly updating or creating a hardware\_product\_profile
as needed.

## delete

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
