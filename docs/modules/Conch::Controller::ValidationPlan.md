# Conch::Controller::Validation

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Controller/ValidationPlan.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Controller/ValidationPlan.pm)

Controller for managing Validation Plans

## METHODS

### get\_all

List all available Validation Plans.

Response uses the ValidationPlans json schema.

### find\_validation\_plan

Chainable action that uses the `validation_plan_id_or_name` provided in the stash
(usually via the request URL) to look up a validation\_plan, and stashes the result in
`validation_plan`.

### get

Get the (active) Validation Plan specified by uuid or name.

Response uses the ValidationPlan json schema.

### get\_validations

List all Validations associated with the Validation Plan, both active and deactivated.

Response uses the Validations json schema.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
