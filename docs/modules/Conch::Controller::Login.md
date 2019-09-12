# NAME

Conch::Controller::Login

# METHODS

## \_respond\_with\_jwt

Create a response containing a login JWT, which the user should later present in the
'Authorization Bearer' header.

## authenticate

Handle the details of authenticating the user, with one of the following options:

```
* existing session for the user
* signed JWT in the Authorization Bearer header
* Old 'conch' session cookie
```

Does not terminate the connection if authentication is successful, allowing for chaining to
subsequent routes and actions.

## session\_login

Handles the act of logging in, given a user and password in the form.
Response uses the Login json schema, containing a JWT.

## session\_logout

Logs a user out by expiring their session

## refresh\_token

Refresh a user's JWT token. Deletes the old token and expires the session.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
