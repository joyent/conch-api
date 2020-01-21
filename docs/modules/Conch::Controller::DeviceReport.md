# Conch::Controller::DeviceReport

## DESCRIPTION

Controller for processing and managing device reports.

## METHODS

### process

Processes the device report, turning it into the various device\_ tables as well
as running validations

Response uses the ValidationStateWithResults json schema.

### \_record\_device\_configuration

Uses a device report to populate configuration information about the given device

### find\_device\_report

Chainable action that uses the `device_report_id` value provided in the stash (usually via the
request URL) to look up a device report, and stashes the query to get to it in
`device_report_rs`.

`device_id` is also saved to the stash.

Role checks are done in the next controller action in the chain.

### get

Get the device\_report record specified by uuid.
A role check has already been done by [device#find\_device](../modules/Conch%3A%3AController%3A%3ADevice#find_device).

Response uses the DeviceReportRow json schema.

### validate\_report

Process a device report without writing anything to the database; otherwise behaves like
["process"](#process). The described device does not have to exist.

Response uses the ReportValidationResults json schema.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
