# Conch::Route::ValidationState

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/ValidationState.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/ValidationState.pm)

## METHODS

### routes

Sets up the routes for /validation\_state.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /validation_state/:validation_state_id`

- Controller/Action: ["get" in Conch::Controller::ValidationState](../modules/Conch%3A%3AController%3A%3AValidationState#get)
- Response: [response.json#/$defs/ValidationStateWithResults](../json-schema/response.json#/$defs/ValidationStateWithResults)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
