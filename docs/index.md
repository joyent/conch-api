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

Our development process is documented over [here](development.html)

# Routes / URLs

* [Conch::Route::Datacenter](modules/conch-route-datacenter)
  * `/dc`
  * `/room`
  * `/rack_role`
  * `/layout`

* [Conch::Route::Device](modules/conch-route-device)
  * `/device`

* [Conch::Route::DeviceReport](modules/conch-route-devicereport)
  * `/device_report`

* [Conch::Route::HardwareProduct](modules/conch-route-hardwareproduct)
  * `/hardware_product`

* [Conch::Route::HardwareVendor](modules/conch-route-hardwarevendor)
  * `/hardware_vendor`

* [Conch::Route::Relay](modules/conch-route-relay)
  * `/relay`

* [Conch::Route::User](modules/conch-route-user)
  * `/user`

* [Conch:Route::Validation](modules/conch-route-validation)
  * `/validation`
  * `/validation_plan`
  * `/validation_state`

* [Conch::Route::Workspace](modules/conch-route-workspace)
  * `/workspace`

# Copyright / License

Copyright Joyent Inc

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, you can obtain one at <http://mozilla.org/MPL/2.0/>
