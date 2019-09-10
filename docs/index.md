# Introduction

The Conch ecosystem is designed to make the deployment of new server hardware
easier, specifically targetting equipment to be used in the Joyent
SmartDatacenter product line.

Conch has two major backend systems.

First, edge software boots new hardware, upgrades firmware, performs burn-in
testing, and gathers the general state of the hardware. (This software is
currently closed source.)

Second, this edge data is fed into the Conch API (this codebase) where the data
is processed, validated, stored, and reported upon.

# The Ecosystem

* [The Web UI](https://github.com/joyent/conch-ui)
* [The CLI Tooling](https://github.com/joyent/conch-shell)

# Development

Our development process is documented over [here](development).

# Routes / URLs

Unless otherwise specified, all routes require authentication: a user must
[POST /login](modules/Conch::Route#post-login) first, and
then use the provided [JSON Web Token](https://tools.ietf.org/html/rfc7519) for subsequent
requests.

Full access is granted to system admin users; otherwise, access restrictions are as noted.

The majority of our endpoints consume and respond with JSON documents that
conform to a set of JSON schema. These schema can be found in the [json-schema](json-schema)
directory in the main repository, as well as on this documentation site.

Successful (http 2xx code) response structures are as described for each endpoint.

Error responses will use:

- failure to validate query parameters: http 400, [response.json#/definitions/QueryParamsValidationError](json-schema/response.json#/definitions/QueryParamsValidationError)
- failure to validate request body payload: http 400, [response.json#/definitions/RequestValidationError](json-schema/response.json#/definitions/RequestValidationError)
- all other errors, unless specified: http 4xx, [response.json#/definitions/Error](json-schema/response.json#/definitions/Error)

Available routes are:

* [Conch::Route](modules/Conch::Route)
  * `/ping`
  * `/version`
  * `/login`
  * `/logout`
  * `/refresh_token`
  * `/me`
  * `/schema`

* [Conch::Route::Datacenter](modules/Conch::Route::Datacenter)
  * `/dc`

* [Conch::Route::Device](modules/Conch::Route::Device)
  * `/device`

* [Conch::Route::DeviceReport](modules/Conch::Route::DeviceReport)
  * `/device_report`

* [Conch::Route::HardwareProduct](modules/Conch::Route::HardwareProduct)
  * `/hardware_product`

* [Conch::Route::HardwareVendor](modules/Conch::Route::HardwareVendor)
  * `/hardware_vendor`

* [Conch::Route::RackLayout](modules/Conch::Route::RackLayout)
  * `/layout`

* [Conch::Route::Organization](modules/Conch::Route::Organization)
  * `/organization`

* [Conch::Route::Rack](modules/Conch::Route::Rack)
  * `/rack`

* [Conch::Route::RackRole](modules/Conch::Route::RackRole)
  * `/rack_role`

* [Conch::Route::Relay](modules/Conch::Route::Relay)
  * `/relay`

* [Conch::Route::DatacenterRoom](modules/Conch::Route::DatacenterRoom)
  * `/room`

* [Conch::Route::User](modules/Conch::Route::User)
  * `/user`

* [Conch:Route::Validation](modules/Conch::Route::Validation)
  * `/validation`
  * `/validation_plan`
  * `/validation_state`

* [Conch::Route::Workspace](modules/Conch::Route::Workspace)
  * `/workspace`

# Modules

Individual module documentation can be found [here](modules).

Script documentation can be found [here](scripts).

JSON Schema defining request and response payloads can be found [here](json-schema).

# Copyright / License

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, you can
obtain one at <http://mozilla.org/MPL/2.0/>.
