# NAME

Conch::Route::Workspace

# METHODS

## routes

Sets up the routes for /workspace:

```perl
GET     /workspace
GET     /workspace/:workspace_id_or_name
GET     /workspace/:workspace_id_or_name/child
POST    /workspace/:workspace_id_or_name/child

GET     /workspace/:workspace_id_or_name/device
GET     /workspace/:workspace_id_or_name/device/active
GET     /workspace/:workspace_id_or_name/device/pxe

GET     /workspace/:workspace_id_or_name/rack
POST    /workspace/:workspace_id_or_name/rack
GET     /workspace/:workspace_id_or_name/rack/:rack_id
DELETE  /workspace/:workspace_id_or_name/rack/:rack_id
POST    /workspace/:workspace_id_or_name/rack/:rack_id/layout

GET     /workspace/:workspace_id_or_name/relay
GET     /workspace/:workspace_id_or_name/relay/:relay_id/device

GET     /workspace/:workspace_id_or_name/user
POST    /workspace/:workspace_id_or_name/user?send_mail=<1|0>
DELETE  /workspace/:workspace_id_or_name/user/#target_user_id_or_email
```

Note that in all routes using `:workspace_id_or_name`, the stash for `workspace_id` will be
populated, as well as `workspace_name` if the identifier was not a UUID.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
