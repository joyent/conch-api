# NAME

Conch::Route::HardwareProduct

# METHODS

## routes

Sets up the routes for /hardware\_product:

```
GET     /hardware_product
POST    /hardware_product

        key is one of: name, alias, sku
GET     /hardware_product/:hardware_product_id
GET     /hardware_product/:hardware_product_key=value
POST    /hardware_product/:hardware_product_id
POST    /hardware_product/:hardware_product_key=value
DELETE  /hardware_product/:hardware_product_id
DELETE  /hardware_product/:hardware_product_key=value
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
