# Conch::Route::Validation

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Validation.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/Validation.pm)

## METHODS

### routes

Sets up the routes for /validation.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /validation`

- Controller/Action: ["get\_all" in Conch::Controller::Validation](../modules/Conch%3A%3AController%3A%3AValidation#get_all)
- Response: [response.json#/definitions/Validations](../json-schema/response.json#/definitions/Validations)

### `GET /validation/:validation_id_or_name`

- Controller/Action: ["get" in Conch::Controller::Validation](../modules/Conch%3A%3AController%3A%3AValidation#get)
- Response: [response.json#/definitions/Validation](../json-schema/response.json#/definitions/Validation)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
