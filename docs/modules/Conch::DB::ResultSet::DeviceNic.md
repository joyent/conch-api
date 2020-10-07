# Conch::DB::ResultSet::DeviceNic

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/DeviceNic.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/DB/ResultSet/DeviceNic.pm)

## DESCRIPTION

Interface to queries involving device network interfaces.

## METHODS

### nic\_pxe

Returns a resultset which provides the MAC address of the relevant PXE network interface(s)
(the first-by-name interface whose state = 'up').

Suitable for embedding as a sub-query.

### nic\_ipmi

Returns a resultset which provides the MAC address and IP address (as an arrayref) of the
network interface(s) named "ipmi1".

Suitable for embedding as a sub-query; post-processing will be required to extract the two
columns into the desired format.

### fields

The list of fields associated with each network interface entry.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
