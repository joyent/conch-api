# Conch::Route::User

## SOURCE

[https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/User.pm](https://github.com/joyent/conch-api/blob/master/lib/Conch/Route/User.pm)

## METHODS

### routes

Sets up the routes for /user.

## ROUTE ENDPOINTS

All routes require authentication.

### `GET /user/me`

- Controller/Action: ["get" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#get)
- Response: [response.json#/$defs/UserDetailed](../json-schema/response.json#/$defs/UserDetailed)

### `POST /user/me?send_mail=<1|0>`

Optionally take the query parameter `send_mail` (defaults to `1`) to send
an email telling the user their account was updated.

- Controller/Action: ["update" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#update)
- Request: [request.json#/$defs/UpdateUser](../json-schema/request.json#/$defs/UpdateUser)
- Response: `204 No Content`, plus Location header
- Error response on duplicate user: [response.json#/$defs/UserError](../json-schema/response.json#/$defs/UserError) (only if the
calling user is a system admin)

### `POST /user/me/revoke?send_mail=<1|0>&login_only=<0|1>&api_only=<0|1>`

Optionally accepts the following query parameters:

- `send_mail=<1|0>` (default `1`) - send an email telling the user their tokens were revoked
- `login_only=<0|1>` (default `0`) - revoke only login/session tokens
- `api_only=<0|1>` (default `0`) - revoke only API tokens

By default it will revoke both login/session and API tokens.
`api_only` and `login_only` cannot both be `1`.

- Controller/Action: ["revoke\_user\_tokens" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#revoke_user_tokens)
- Request: [request.json#/$defs/UserSettings](../json-schema/request.json#/$defs/UserSettings)
- Response: `204 No Content`

### `POST /user/me/password?clear_tokens=<login_only|none|all>`

Optionally takes a query parameter `clear_tokens`, to also revoke the session
tokens for the user, forcing the user to log in again. Possible options are:

- `none`
- `login_only`
- `all` - clear all tokens (login and api - affects all APIs and tools)

If the `clear_tokens` parameter is set to `none` then the user session will remain;
otherwise, the user is logged out.

- Controller/Action: ["change\_own\_password" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#change_own_password)
- Request: [request.json#/$defs/UserSettings](../json-schema/request.json#/$defs/UserSettings)
- Response: `204 No Content`

### `GET /user/me/settings`

- Controller/Action: ["get\_settings" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#get_settings)
- Response: [response.json#/$defs/UserSettings](../json-schema/response.json#/$defs/UserSettings)

### `POST /user/me/settings`

- Controller/Action: ["set\_settings" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#set_settings)
- Request: [request.json#/$defs/UserSettings](../json-schema/request.json#/$defs/UserSettings)
- Response: `204 No Content`

### `GET /user/me/settings/:key`

- Controller/Action: ["get\_setting" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#get_setting)
- Response: [response.json#/$defs/UserSetting](../json-schema/response.json#/$defs/UserSetting)

### `POST /user/me/settings/:key`

- Controller/Action: ["set\_setting" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#set_setting)
- Request: [request.json#/$defs/UserSetting](../json-schema/request.json#/$defs/UserSetting)
- Response: `204 No Content`

### `DELETE /user/me/settings/:key`

- Controller/Action: ["delete\_setting" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#delete_setting)
- Response: `204 No Content`

### `GET /user/me/token`

- Controller/Action: ["get\_api\_tokens" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#get_api_tokens)
- Response: [response.json#/$defs/UserTokens](../json-schema/response.json#/$defs/UserTokens)

### `POST /user/me/token`

- Controller/Action: ["create\_api\_token" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#create_api_token)
- Request: [request.json#/$defs/NewUserToken](../json-schema/request.json#/$defs/NewUserToken)
- Response: [response.json#/$defs/NewUserToken](../json-schema/response.json#/$defs/NewUserToken)

### `GET /user/me/token/:token_name`

- Controller/Action: ["get\_api\_token" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#get_api_token)
- Response: [response.json#/$defs/UserToken](../json-schema/response.json#/$defs/UserToken)

### `DELETE /user/me/token/:token_name`

- Controller/Action: ["expire\_api\_token" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#expire_api_token)
- Response: `204 No Content`

### `GET /user/:target_user_id_or_email`

- Requires system admin authorization (when updating a different account than one's own)
- Controller/Action: ["get" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#get)
- Response: [response.json#/$defs/UserDetailed](../json-schema/response.json#/$defs/UserDetailed)

### `POST /user/:target_user_id_or_email?send_mail=<1|0>`

Optionally take the query parameter `send_mail` (defaults to `1`) to send
an email telling the user their account was updated.

- Requires system admin authorization
- Controller/Action: ["update" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#update)
- Request: [request.json#/$defs/UpdateUser](../json-schema/request.json#/$defs/UpdateUser)
- Response: `204 No Content`, plus Location header
- Error response on duplicate user: [response.json#/$defs/UserError](../json-schema/response.json#/$defs/UserError) (only if the
calling user is a system admin)

### `DELETE /user/:target_user_id_or_email?clear_tokens=<1|0>`

When a user is deleted, all role entries (build, organization) are removed and are
unrecoverable.

Optionally takes a query parameter `clear_tokens` (defaults to `1`), to also
revoke all session tokens for the user forcing all tools to log in again.

- Requires system admin authorization
- Controller/Action: ["deactivate" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#deactivate)
- Response: `204 No Content`

### `POST /user/:target_user_id_or_email/revoke?login_only=<0|1>&api_only=<0|1>`

Optionally accepts the following query parameters:

- `login_only=<0|1>` (default `0`) - revoke only login/session tokens
- `api_only=<0|1>` (default `0`) - revoke only API tokens

By default it will revoke both login/session and API tokens. If both
`api_only` and `login_only` cannot both be `1`.

- Requires system admin authorization
- Controller/Action: ["revoke\_user\_tokens" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#revoke_user_tokens)
- Response: `204 No Content`

### `DELETE /user/:target_user_id_or_email/password?clear_tokens=<login_only|none|all>&send_mail=<1|0>`

Optionally accepts the following query parameters:

- `clear_tokens` (default `login_only`) to also revoke tokens for the user, takes the following possible values:
    - `none`
    - `login_only`
    - `all` - clear all tokens (login and api - affects all APIs and tools)
- `send_mail` which takes `<1|0>` (defaults to `1`) to send an email to the user with password reset instructions.

- Requires system admin authorization
- Controller/Action: ["reset\_user\_password" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#reset_user_password)
- Response: `204 No Content`

### `GET /user`

- Requires system admin authorization
- Controller/Action: ["get\_all" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#get_all)
- Response: [response.json#/$defs/Users](../json-schema/response.json#/$defs/Users)

### `POST /user?send_mail=<1|0>`

Optionally takes a query parameter, `send_mail` (defaults to `1`) to send an
email to the user with the new password.

- Requires system admin authorization
- Controller/Action: ["create" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#create)
- Request: [request.json#/$defs/NewUser](../json-schema/request.json#/$defs/NewUser)
- Success Response: [response.json#/$defs/NewUser](../json-schema/response.json#/$defs/NewUser)
- Error response on duplicate user: [response.json#/$defs/UserError](../json-schema/response.json#/$defs/UserError)

### `GET /user/:target_user_id_or_email/token`

- Requires system admin authorization
- Controller/Action: ["get\_api\_tokens" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#get_api_tokens)
- Response: [response.json#/$defs/UserTokens](../json-schema/response.json#/$defs/UserTokens)

### `GET /user/:target_user_id_or_email/token/:token_name`

- Requires system admin authorization
- Controller/Action: ["get\_api\_token" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#get_api_token)
- Response: [response.json#/$defs/UserTokens](../json-schema/response.json#/$defs/UserTokens)

### `DELETE /user/:target_user_id_or_email/token/:token_name`

- Requires system admin authorization
- Controller/Action: ["expire\_api\_token" in Conch::Controller::User](../modules/Conch%3A%3AController%3A%3AUser#expire_api_token)
- Success Response: `204 No Content`
- Error response when user already deactivated: [response.json#/$defs/UserError](../json-schema/response.json#/$defs/UserError)

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
