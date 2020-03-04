# NAME

Conch::Plugin::Mail - Sets up a helper to send emails

## DESCRIPTION

Provides the helper sub 'send\_mail' to the app and controllers:

```perl
$c->send_mail(
    template_file => $filename, # file in templates/email, without extension
        OR
    template => $template_string,
        OR
    content => $raw_content,

    to => $to_email,        defaults to stashed 'target_user'
    from => $from_email,    defaults to stashed 'user'
    subject => $subject,

    ... all additional arguments are passed to the template renderer ...
);
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
