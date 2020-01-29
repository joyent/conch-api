# Conch::Plugin::Mail

## SOURCE

[https://github.com/joyent/conch/blob/master/lib/Conch/Plugin/Mail.pm](https://github.com/joyent/conch/blob/master/lib/Conch/Plugin/Mail.pm)

## DESCRIPTION

Helper methods for sending emails

## HELPERS

These methods are made available on the `$c` object (the invocant of all controller methods,
and therefore other helpers).

### send\_mail

```perl
$c->send_mail(
    template_file => $filename, # file in templates/email, without extension
        # OR
    template => $template_string,
        # OR
    content => $raw_content,

    To => $to_email,        # defaults to stashed 'target_user'
    From => $from_email,    # defaults to stashed 'user'
    Subject => $subject,

    # ... all additional arguments are passed to the template renderer ...
);
```

### construct\_address\_list

Given a list of [user](../modules/Conch%3A%3ADB%3A%3AResult%3A%3AUserAccount) records, returns a string suitable to be
used in a `To` header, comprising names and email addresses.

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
