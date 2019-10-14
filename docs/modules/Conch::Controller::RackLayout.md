# NAME

Conch::Controller::RackLayout

# METHODS

## find\_rack\_layout

Supports rack layout lookups by id.

## create

Creates a new rack\_layout entry according to the passed-in specification.

## get

Gets one specific rack layout.

Response uses the RackLayout json schema.

## get\_all

Gets **all** rack layouts.

Response uses the RackLayouts json schema.

## update

Updates a rack layout to specify that a certain hardware product should reside at a certain
rack starting position.

## delete

Deletes the specified rack layout.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
