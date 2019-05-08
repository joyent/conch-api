# NAME

Conch::Controller::Login

# METHODS

## \_create\_jwt

Create a JWT and sets it up to be returned in the response in two parts:

```perl
* the signature in a cookie named 'jwt_sig',
* and a response body named 'jwt_token'. 'jwt_token' includes two claims: 'uid', for the
  user ID, and 'jti', for the token ID.
```

## authenticate

Handle the details of authenticating the user, with one of the following options:

```perl
* existing session for the user
* JWT split between Authorization Bearer header value and jwt_sig cookie
* JWT combined with a Authorization Bearer header using format "$jwt_token.$jwt_sig"
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
