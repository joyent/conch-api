# NAME

Conch::Route::Device

# METHODS

## routes

Sets up the routes for /device:

```
GET     /device/?hostname=:host, ?mac=:mac, ?ipaddr=:ipaddr, ?:setting_key=:setting_value
GET     /device/:device_id
GET     /device/:device_id/pxe
GET     /device/:device_id/phase
POST    /device/:device_id
POST    /device/:device_id/graduate
POST    /device/:device_id/triton_setup
POST    /device/:device_id/triton_uuid
POST    /device/:device_id/triton_reboot
POST    /device/:device_id/asset_tag
POST    /device/:device_id/validated
POST    /device/:device_id/phase

GET     /device/:device_id/location
POST    /device/:device_id/location
DELETE  /device/:device_id/location

GET     /device/:device_id/settings
POST    /device/:device_id/settings
GET     /device/:device_id/settings/#key
POST    /device/:device_id/settings/#key
DELETE  /device/:device_id/settings/#key

POST    /device/:device_id/validation/:validation_id
POST    /device/:device_id/validation_plan/:validation_plan_id
GET     /device/:device_id/validation_state

GET     /device/:device_id/interface
GET     /device/:device_id/interface/:interface_name
GET     /device/:device_id/interface/:interface_name/:field
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
