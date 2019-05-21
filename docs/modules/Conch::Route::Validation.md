# NAME

Conch::Route::Validation

# METHODS

## routes

Sets up the routes for /validation, /validation\_plan and /validation\_state:

Unless otherwise noted, all routes require authentication.

### `GET /validation`

- Response: response.yaml#/Validations

### `GET /validation/:validation_id_or_name`

- Response: response.yaml#/Validation

### `GET /validation_plan`

- Response: response.yaml#/ValidationPlans

### `GET /validation_plan/:validation_plan_id_or_name`

- Response: response.yaml#/ValidationPlan

### `GET /validation_plan/:validation_plan_id_or_name/validation`

- Response: response.yaml#/Validations

### `GET /validation_state/:validation_state_id`

- Response: response.yaml#/ValidationStateWithResults

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
