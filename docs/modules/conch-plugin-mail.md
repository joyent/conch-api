# NAME

Conch::Plugin::Mail - Sets up a helper to send emails

## DESCRIPTION

Provides the helper sub 'send\_mail' to the app and controllers:

```perl
$c->send_mail('workspace_add_user', {
    name => 'bob',
    email => 'bob@conch.joyent.us',
});
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
