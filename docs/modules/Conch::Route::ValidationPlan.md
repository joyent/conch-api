# Conch::Route::ValidationPlan

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/ValidationPlan.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/ValidationPlan.pm)

## METHODS

### routes

Sets up the routes for /validation\_plan.

All routes are **deprecated** and will be removed in Conch API v4.0.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /validation_plan`

- Controller/Action: ["get\_all" in Conch::Controller::ValidationPlan](../modules/Conch%3A%3AController%3A%3AValidationPlan#get_all)
- Response: [response.json#/$defs/LegacyValidationPlans](../json-schema/response.json#/$defs/LegacyValidationPlans)

### `GET /validation_plan/:legacy_validation_plan_id_or_name`

- Controller/Action: ["get" in Conch::Controller::ValidationPlan](../modules/Conch%3A%3AController%3A%3AValidationPlan#get)
- Response: [response.json#/$defs/LegacyValidationPlan](../json-schema/response.json#/$defs/LegacyValidationPlan)

### `GET /validation_plan/:legacy_validation_plan_id_or_name/validation`

- Controller/Action: ["validations" in Conch::Controller::ValidationPlan](../modules/Conch%3A%3AController%3A%3AValidationPlan#validations)
- Response: [response.json#/$defs/LegacyValidations](../json-schema/response.json#/$defs/LegacyValidations)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
