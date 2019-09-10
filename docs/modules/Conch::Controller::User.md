# NAME

Conch::Controller::User

# METHODS

## find\_user

Chainable action that validates the `target_user_id_or_email` provided in the path, and
stashes the corresponding user row in `target_user`.

## revoke\_user\_tokens

Revoke a specified user's tokens and prevents future token authentication,
forcing the user to /login again. By default \*all\* of a user's tokens are deleted,
but this can be adjusted with query parameters:

```
* C<?login_only=1> login tokens are removed; api tokens are left alone
* C<?api_only=1>   login tokens are left alone; api tokens are removed
```

If login tokens are affected, `user_session_auth` is also set for the user, which forces the
user to change his password as soon as a login token is used again (but use of any existing api
tokens is allowed).

System admin only (unless reached via /user/me).

Sends an email to the affected user, unless `?send_mail=0` is included in the query (or
revoking for oneself).

## set\_settings

Override the settings for a user with the provided payload

## set\_setting

Set the value of a single setting for the target user.

FIXME: the key name is repeated in the URL and the payload :(

## get\_settings

Get the key/values of every setting for a user.

Response uses the UserSettings json schema.

## get\_setting

Get the individual key/value pair for a setting for the target user.

Response uses the UserSetting json schema.

## delete\_setting

Delete a single setting for a user, provided it was set previously.

## change\_own\_password

Stores a new password for the current user.

Optionally takes a query parameter `clear_tokens`, to also revoke session tokens for the user,
forcing the user to log in again. Possible options are:

```
* none
* login_only (default) - clear login tokens only
* all - clear all tokens (login and api - affects all APIs and tools)
```

When login tokens are cleared, the user is also logged out.

## reset\_user\_password

Generates a new random password for a user. System admin only.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an
email to the user with the new password.

Optionally takes a query parameter `clear_tokens`, to also revoke session tokens for the user,
forcing the user to log in again. Possible options are:

```
* none
* login_only (default)
* all - clear all tokens (login and api - affects all APIs and tools)
```

If all tokens are revoked, the user must also change their password after logging in, as they
will not be able to log in with it again.

## get

Gets information about a user. System admin only (unless reached via /user/me).
Response uses the UserDetailed json schema.

## update

Updates user attributes. System admin only.
Sends an email to the affected user, unless `?send_mail=0` is included in the query.

The response uses the UserError json schema for some error conditions; on success, redirects to
`GET /user/:id`.

## list

List all active users and their workspaces. System admin only.
Response uses the UsersDetailed json schema.

## create

Creates a user. System admin only.

Optionally takes a query parameter `send_mail` (defaulting to true), to send an
email to the user with the new password.

Response uses the NewUser json schema (or UserError for some error conditions).

## deactivate

Deactivates a user. System admin only.

Optionally takes a query parameter `clear_tokens` (defaulting to true), to also revoke all
session tokens for the user, which would force all tools to log in again should the account be
reactivated (for which there is no api endpoint at present).

All memberships in workspaces and organizations are removed and are not recoverable.

Response uses the UserError json schema on some error conditions.

## get\_api\_tokens

Get a list of unexpired tokens for the user (api only).

Response uses the UserTokens json schema.

## create\_api\_token

Generate a new token, creating a JWT from it. Response uses the NewUserToken json schema.
This is the only time the token string is provided to the user, so don't lose it!

## find\_api\_token

Chainable action that takes the `token_name` provided in the path and looks it up in the
database, stashing a resultset to access it as `token_rs`.

Only api tokens may be retrieved by this flow.

## get\_api\_token

Get information about the specified (unexpired) api token.

Response uses the UserToken json schema.

## expire\_api\_token

Deactivates an api token from future use.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
