# NAME

Conch::Plugin::Mail

## DESCRIPTION

Helper methods for sending emails

## HELPERS

## send\_mail

```perl
$c->send_mail(
    template_file => $filename, # file in templates/email, without extension
        OR
    template => $template_string,
        OR
    content => $raw_content,

    To => $to_email,        defaults to stashed 'target_user'
    From => $from_email,    defaults to stashed 'user'
    Subject => $subject,

    ... all additional arguments are passed to the template renderer ...
);
```

## construct\_address\_list

Given a list of [user](../modules/Conch::DB::Result::UserAccount) records, returns a string suitable to be
used in a `To` header, comprising names and email addresses.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
