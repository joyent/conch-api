# Conch::Route::Validation

## METHODS

### routes

Sets up the routes for /validation, /validation\_plan and /validation\_state.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /validation`

- Response: [response.json#/definitions/Validations](../json-schema/response.json#/definitions/Validations)

### `GET /validation/:validation_id_or_name`

- Response: [response.json#/definitions/Validation](../json-schema/response.json#/definitions/Validation)

### `GET /validation_plan`

- Response: [response.json#/definitions/ValidationPlans](../json-schema/response.json#/definitions/ValidationPlans)

### `GET /validation_plan/:validation_plan_id_or_name`

- Response: [response.json#/definitions/ValidationPlan](../json-schema/response.json#/definitions/ValidationPlan)

### `GET /validation_plan/:validation_plan_id_or_name/validation`

- Response: [response.json#/definitions/Validations](../json-schema/response.json#/definitions/Validations)

### `GET /validation_state/:validation_state_id`

- Response: [response.json#/definitions/ValidationStateWithResults](../json-schema/response.json#/definitions/ValidationStateWithResults)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
