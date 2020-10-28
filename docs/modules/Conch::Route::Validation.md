# Conch::Route::Validation

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Validation.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Validation.pm)

## METHODS

### routes

Sets up the routes for /validation.

All routes are **deprecated** and will be removed in Conch API v3.1.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /validation`

- Controller/Action: ["get\_all" in Conch::Controller::Validation](../modules/Conch%3A%3AController%3A%3AValidation#get_all)
- Response: [response.json#/definitions/LegacyValidations](../json-schema/response.json#/definitions/LegacyValidations)

### `GET /validation/:legacy_validation_id_or_name`

- Controller/Action: ["get" in Conch::Controller::Validation](../modules/Conch%3A%3AController%3A%3AValidation#get)
- Response: [response.json#/definitions/LegacyValidation](../json-schema/response.json#/definitions/LegacyValidation)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
