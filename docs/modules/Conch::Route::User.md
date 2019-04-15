# NAME

Conch::Route::User

# METHODS

## routes

Sets up the routes for /user:

```perl
GET     /user/me
POST    /user/me/revoke?send_mail=<1|0>& login_only=<0|1> or ?api_only=<0|1>
POST    /user/me/password?clear_tokens=<login_only|0|all>
GET     /user/me/settings
POST    /user/me/settings
GET     /user/me/settings/#key
POST    /user/me/settings/#key
DELETE  /user/me/settings/#key

GET     /user/me/token
POST    /user/me/token
GET     /user/me/token/*token_name
DELETE  /user/me/token/*token_name

GET     /user/#target_user_id_or_email
POST    /user/#target_user_id_or_email?send_mail=<1|0>
DELETE  /user/#target_user_id_or_email?clear_tokens=<1|0>
POST    /user/#target_user_id_or_email/revoke?login_only=<0|1> or ?api_only=<0|1>
DELETE  /user/#target_user_id_or_email/password?clear_tokens=<login_only|0|all>&send_password_reset_mail=<1|0>

GET     /user/#target_user_id_or_email/token
GET     /user/#target_user_id_or_email/token/*token_name
DELETE  /user/#target_user_id_or_email/token/*token_name

GET     /user
POST    /user?send_mail=<1|0>
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
