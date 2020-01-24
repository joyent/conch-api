# Conch::Route::DeviceReport

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Route/DeviceReport.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Route/DeviceReport.pm)

## METHODS

### routes

Sets up the routes for /device\_report.

## ROUTE ENDPOINTS

All routes require authentication.

### `POST /device_report`

- Request: [device_report.json#/definitions/DeviceReport](../json-schema/device_report.json#/definitions/DeviceReport)
- Response: [response.json#/definitions/ReportValidationResults](../json-schema/response.json#/definitions/ReportValidationResults)

### `GET /device_report/:device_report_id`

- User requires the read-only role, as described in ["routes" in Conch::Route::Device](../modules/Conch%3A%3ARoute%3A%3ADevice#routes).
- Response: [response.json#/definitions/DeviceReportRow](../json-schema/response.json#/definitions/DeviceReportRow)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
