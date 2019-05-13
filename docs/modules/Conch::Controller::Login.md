# NAME

Conch::Controller::Login

# METHODS

## \_create\_jwt

Create a JWT and sets it up to be returned in the response body under the key 'jwt\_token'.

## authenticate

Handle the details of authenticating the user, with one of the following options:

```perl
* existing session for the user
* signed JWT in the Authorization Bearer header
* Old 'conch' session cookie
```

Does not terminate the connection if authentication is successful, allowing for chaining to
subsequent routes and actions.

## session\_login

Handles the act of logging in, given a user and password in the form. Returns a JWT token.

## session\_logout

Logs a user out by expiring their session

## refresh\_token

Refresh a user's JWT token. Deletes the old token.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
