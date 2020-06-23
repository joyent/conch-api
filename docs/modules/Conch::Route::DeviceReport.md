# Conch::Route::DeviceReport

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route/DeviceReport.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route/DeviceReport.pm)

## METHODS

### routes

Sets up the routes for /device\_report.

## ROUTE ENDPOINTS

All routes require authentication.

### `POST /device_report`

Submits a device report for processing. The device must already exist.
Device data will be updated in the database.

- The authenticated user must have previously registered the relay being used for the
report submission (as indicated via `#/relay/serial` in the report).
- Controller/Action: ["process" in Conch::Controller::DeviceReport](../modules/Conch%3A%3AController%3A%3ADeviceReport#process)
- Request: [request.json#/definitions/DeviceReport](../json-schema/request.json#/definitions/DeviceReport)
- Response: [response.json#/definitions/ValidationStateWithResults](../json-schema/response.json#/definitions/ValidationStateWithResults)

### `POST /device_report?no_update_db=1`

Submits a device report for processing. Device data will **not** be updated in the database;
only validations will be run.

- Controller/Action: ["validate\_report" in Conch::Controller::DeviceReport](../modules/Conch%3A%3AController%3A%3ADeviceReport#validate_report)
- Request: [request.json#/definitions/DeviceReport](../json-schema/request.json#/definitions/DeviceReport)
- Response: [response.json#/definitions/ReportValidationResults](../json-schema/response.json#/definitions/ReportValidationResults)

### `GET /device_report/:device_report_id`

- User requires the read-only role, as described in ["routes" in Conch::Route::Device](../modules/Conch%3A%3ARoute%3A%3ADevice#routes).
- Controller/Action: ["get" in Conch::Controller::DeviceReport](../modules/Conch%3A%3AController%3A%3ADeviceReport#get)
- Response: [response.json#/definitions/DeviceReportRow](../json-schema/response.json#/definitions/DeviceReportRow)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
