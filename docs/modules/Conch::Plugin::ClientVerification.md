# Conch::Plugin::ClientVerification

## DESCRIPTION

Checks the version of the client sending us a request, possibly rejecting it if it does not
meet our criteria.

For security reasons we do not specify the reason for the rejection in the error response,
but we will log it.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
