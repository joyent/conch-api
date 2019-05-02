# NAME

Conch::Controller::WorkspaceDevice

# METHODS

## list

Get a list of all active devices in the current workspace (as specified by :workspace\_id in the
path).

Supports these query parameters to constrain results (which are ANDed together, not ORed):

```
graduated=T     only devices with graduated set
graduated=F     only devices with graduated not set
validated=T     only devices with validated set
validated=F     only devices with validated not set
health=<value>  only devices with health matching provided value (case-insensitive)
active=1        only devices last seen within 5 minutes (FIXME: ambiguous name)
ids_only=1      only return device ids, not full data
```

Response uses the Devices json schema.

## get\_pxe\_devices

Response uses the WorkspaceDevicePXEs json schema.

## device\_totals

Ported from 'conch-stats'.

Response uses the 'DeviceTotals' and 'DeviceTotalsCirconus' json schemas.
Add '.circ' to the end of the URL to select the data format customized for Circonus.

Note that this is an unauthenticated endpoint.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
