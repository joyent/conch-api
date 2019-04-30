# NAME

Conch::Route::Validation

# METHODS

## routes

Sets up the routes for /validation, /validation\_plan and /validation\_state:

```
GET     /validation
GET     /validation/:validation_id_or_name

GET     /validation_plan
GET     /validation_plan/:validation_plan_id_or_name
GET     /validation_plan/:validation_plan_id_or_name/validation

GET     /validation_state/:validation_state_id
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
