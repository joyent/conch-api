# NAME

Conch::Controller::Login

# METHODS

## \_respond\_with\_jwt

Create a response containing a login JWT, which the user should later present in the
'Authorization Bearer' header.

## authenticate

Handle the details of authenticating the user, with one of the following options:

```
* signed JWT in the Authorization Bearer header
* existing session for the user (using the 'conch' session cookie)
```

Does not terminate the connection if authentication is successful, allowing for chaining to
subsequent routes and actions.

## login

Handles the act of logging in, given a user and password in the form.
Response uses the LoginToken json schema, containing a JWT.

## logout

Logs a user out by expiring their JWT (if one was included with the request) and user session

## refresh\_token

Refresh a user's JWT token and persistent user session, deleting the old token.
Response uses the LoginToken json schema, containing a JWT.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
