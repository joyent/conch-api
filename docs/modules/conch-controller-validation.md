# NAME

Conch::Controller::Validation

Controller for managing Validations, **NOT** executing them.

# METHODS

## list

List all Validations.

Response uses the Validations json schema (including deactivated ones).

## find\_validation

Find the Validation specified by uuid or name, and stashes the query to get to it in
`validation_rs`.

## get

Get the Validation specified by uuid or name.

Response uses the Validation json schema.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
