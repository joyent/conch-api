# Conch::Route::Validation

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Validation.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Validation.pm)

## METHODS

### routes

Sets up the routes for /validation, /validation\_plan and /validation\_state.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /validation`

- Controller/Action: ["get\_all" in Conch::Controller::Validation](../modules/Conch%3A%3AController%3A%3AValidation#get_all)
- Response: [response.json#/definitions/Validations](../json-schema/response.json#/definitions/Validations)

### `GET /validation/:validation_id_or_name`

- Controller/Action: ["get" in Conch::Controller::Validation](../modules/Conch%3A%3AController%3A%3AValidation#get)
- Response: [response.json#/definitions/Validation](../json-schema/response.json#/definitions/Validation)

### `GET /validation_plan`

- Controller/Action: ["get\_all" in Conch::Controller::ValidationPlan](../modules/Conch%3A%3AController%3A%3AValidationPlan#get_all)
- Response: [response.json#/definitions/ValidationPlans](../json-schema/response.json#/definitions/ValidationPlans)

### `GET /validation_plan/:validation_plan_id_or_name`

- Controller/Action: ["get" in Conch::Controller::ValidationPlan](../modules/Conch%3A%3AController%3A%3AValidationPlan#get)
- Response: [response.json#/definitions/ValidationPlan](../json-schema/response.json#/definitions/ValidationPlan)

### `GET /validation_plan/:validation_plan_id_or_name/validation`

- Controller/Action: ["validations" in Conch::Controller::ValidationPlan](../modules/Conch%3A%3AController%3A%3AValidationPlan#validations)
- Response: [response.json#/definitions/Validations](../json-schema/response.json#/definitions/Validations)

### `GET /validation_state/:validation_state_id`

- Controller/Action: ["get" in Conch::Controller::ValidationState](../modules/Conch%3A%3AController%3A%3AValidationState#get)
- Response: [response.json#/definitions/ValidationStateWithResults](../json-schema/response.json#/definitions/ValidationStateWithResults)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
