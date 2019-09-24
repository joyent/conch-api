# NAME

Conch::Controller::DeviceReport

# DESCRIPTION

Controller for processing and managing device reports.

# METHODS

## process

Processes the device report, turning it into the various device\_ tables as well
as running validations

Response uses the ValidationStateWithResults json schema.

## \_record\_device\_configuration

Uses a device report to populate configuration information about the given device

## find\_device\_report

Chainable action that validates the 'device\_report\_id' provided in the path.
Stores the device\_id and device\_report resultset to the stash for later retrieval.

Role checks are done in the next controller action in the chain.

## get

Get the device\_report record specified by uuid.
A role check has already been done by [device#find\_device](../modules/Conch::Controller::Device#find_device).

Response uses the DeviceReportRow json schema.

## validate\_report

Process a device report without writing anything to the database; otherwise behaves like
["process"](#process). The described device does not have to exist.

Response uses the ReportValidationResults json schema.

## \_get\_validation\_plan

Find the validation plan that should be used to validate the device referenced by the
report.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
