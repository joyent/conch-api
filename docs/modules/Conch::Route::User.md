# NAME

Conch::Route::User

# METHODS

## routes

Sets up the routes for /user:

Unless otherwise noted, all routes require authentication.

### `GET /user/me`

- Response: [response.json#/definitions/UserDetailed](../json-schema/response.json#/definitions/UserDetailed)

### `POST /user/me/revoke?send_mail=<1|0>&login_only=<0|1>&api_only=<0|1>`

Optionally accepts the following query parameters:

- `send_mail=<1|0>` (default `1`) - send an email telling the user their tokens were revoked
- `login_only=<0|1>` (default `0`) - revoke only login/session tokens
- `api_only=<0|1>` (default `0`) - revoke only API tokens

By default it will revoke both login/session and API tokens.
`api_only` and `login_only` cannot both be `1`.

- Request: [request.json#/definitions/UserSettings](../json-schema/request.json#/definitions/UserSettings)
- Response: `204 NO CONTENT`

### `POST /user/me/password?clear_tokens=<login_only|none|all>`

Optionally takes a query parameter `clear_tokens`, to also revoke the session
tokens for the user, forcing the user to log in again. Possible options are:

- `none`
- `login_only`
- `all` - clear all tokens (login and api - affects all APIs and tools)

If the `clear_tokens` parameter is set to `none` then the user session will remain;
otherwise, the user is logged out.

- Request: [request.json#/definitions/UserSettings](../json-schema/request.json#/definitions/UserSettings)
- Response: `204 NO CONTENT`

### `GET /user/me/settings`

- Response: [response.json#/definitions/UserSettings](../json-schema/response.json#/definitions/UserSettings)

### `POST /user/me/settings`

- Request: [request.json#/definitions/UserSettings](../json-schema/request.json#/definitions/UserSettings)
- Response: `204 NO CONTENT`

### `GET /user/me/settings/:key`

- Response: [response.json#/definitions/UserSetting](../json-schema/response.json#/definitions/UserSetting)

### `POST /user/me/settings/:key`

- Request: [request.json#/definitions/UserSetting](../json-schema/request.json#/definitions/UserSetting)
- Response: `204 NO CONTENT`

### `DELETE /user/me/settings/:key`

- Response: `204 NO CONTENT`

### `GET /user/me/token`

- Response: [response.json#/definitions/UserTokens](../json-schema/response.json#/definitions/UserTokens)

### `POST /user/me/token`

- Request: [request.json#/definitions/NewUserToken](../json-schema/request.json#/definitions/NewUserToken)
- Response: [response.json#/definitions/NewUserToken](../json-schema/response.json#/definitions/NewUserToken)

### `GET /user/me/token/:token_name`

- Response: [response.json#/definitions/UserToken](../json-schema/response.json#/definitions/UserToken)

### `DELETE /user/me/token/:token_name`

- Response: `204 NO CONTENT`

### `GET /user/:target_user_id_or_email`

- Requires system admin authorization
- Response: [response.json#/definitions/UserDetailed](../json-schema/response.json#/definitions/UserDetailed)

### `POST /user/:target_user_id_or_email?send_mail=<1|0>`

Optionally take the query parameter `send_mail` (defaults to `1`) to send
an email telling the user their tokens were revoked

- Requires system admin authorization
- Request: [request.json#/definitions/UpdateUser](../json-schema/request.json#/definitions/UpdateUser)
- Success Response: Redirect to the user that was updated
- Error response on duplicate user: [response.json#/definitions/UserError](../json-schema/response.json#/definitions/UserError)

### `DELETE /user/:target_user_id_or_email?clear_tokens=<1|0>`

When a user is deleted, all role entries (workspace, build, organization) are removed and are
unrecoverable.

Optionally takes a query parameter `clear_tokens` (defaults to `1`), to also
revoke all session tokens for the user forcing all tools to log in again.

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `POST /user/:target_user_id_or_email/revoke?login_only=<0|1>&api_only=<0|1>`

Optionally accepts the following query parameters:

- `login_only=<0|1>` (default `0`) - revoke only login/session tokens
- `api_only=<0|1>` (default `0`) - revoke only API tokens

By default it will revoke both login/session and API tokens. If both
`api_only` and `login_only` cannot both be `1`.

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `DELETE /user/:target_user_id_or_email/password?clear_tokens=<login_only|none|all>&send_mail=<1|0>`

Optionally accepts the following query parameters:

- `clear_tokens` (default `login_only`) to also revoke tokens for the user, takes the following possible values:
    - `none`
    - `login_only`
    - `all` - clear all tokens (login and api - affects all APIs and tools)
- `send_mail` which takes `<1|0>` (defaults to `1`) to send an email to the user with password reset instructions.

- Requires system admin authorization
- Response: `204 NO CONTENT`

### `GET /user`

- Requires system admin authorization
- Response: [response.json#/definitions/UsersDetailed](../json-schema/response.json#/definitions/UsersDetailed)

### `POST /user?send_mail=<1|0>`

Optionally takes a query parameter, `send_mail` (defaults to `1`) to send an
email to the user with the new password.

- Requires system admin authorization
- Request: [request.json#/definitions/NewUser](../json-schema/request.json#/definitions/NewUser)
- Success Response: [response.json#/definitions/User](../json-schema/response.json#/definitions/User)
- Error response on duplicate user: [response.json#/definitions/UserError](../json-schema/response.json#/definitions/UserError)

### `GET /user/:target_user_id_or_email/token`

- Requires system admin authorization
- Response: [response.json#/definitions/UserTokens](../json-schema/response.json#/definitions/UserTokens)

### `GET /user/:target_user_id_or_email/token/:token_name`

- Requires system admin authorization
- Response: [response.json#/definitions/UserTokens](../json-schema/response.json#/definitions/UserTokens)

### `DELETE /user/:target_user_id_or_email/token/:token_name`

- Requires system admin authorization
- Success Response: `204 NO CONTENT`
- Error response when user already deactivated: [response.json#/definitions/UserError](../json-schema/response.json#/definitions/UserError)

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
