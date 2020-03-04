# NAME

Conch::Route::DeviceReport

# METHODS

## routes

Sets up the routes for /device\_report:

Unless otherwise noted, all routes require authentication.

### `POST /device_report`

- Request: device\_report.yaml
- Response: response.yaml#/ReportValidationResults

### `GET /device_report/:device_report_id`

- Response: response.yaml#/DeviceReportRow

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
