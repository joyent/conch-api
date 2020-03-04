# NAME

Conch::Controller::Validation

Controller for managing Validation Plans

# METHODS

## create

Create new Validation Plan.

## list

List all available Validation Plans.

Response uses the ValidationPlans json schema.

## find\_validation\_plan

Find the Validation Plan specified by uuid or name and put it in the stash as
`validation_plan`.

## get

Get the (active) Validation Plan specified by uuid or name.

Response uses the ValidationPlan json schema.

## list\_validations

List all Validations associated with the Validation Plan, both active and deactivated.

Response uses the Validations json schema.

## add\_validation

Add a validation to a validation plan.

## remove\_validation

Remove a Validation associated with the Validation Plan

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
