# Conch::Controller::RackLayout

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Controller/RackLayout.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Controller/RackLayout.pm)

## METHODS

### find\_rack\_layout

Chainable action that uses the `layout_id_or_rack_unit_start` value provided in the stash
(usually via the request URL) to look up a layout, and stashes the query to get to it in
`layout_rs`.

### create

Creates a new rack\_layout entry according to the passed-in specification.

### get

Gets one specific rack layout.

Response uses the RackLayout json schema.

### get\_all

Gets **all** rack layouts.

Response uses the RackLayouts json schema.

### update

Updates a rack layout to specify that a certain hardware product should reside at a certain
rack starting position.

### delete

Deletes the specified rack layout.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
