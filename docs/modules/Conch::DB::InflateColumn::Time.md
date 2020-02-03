## DESCRIPTION

Automatically inflates/deflates timestamps in the database to [Conch::Time](../modules/Conch%3A%3ATime) objects (which is
a subclass of [Time::Moment](https://metacpan.org/pod/Time%3A%3AMoment)).

No extra work needs to be done for deflation, because postgres is happy to accept our slight
modifications to the format used in `to_string`. All we need to do is rebless the
[Time::Moment](https://metacpan.org/pod/Time%3A%3AMoment) object into [Conch::Time](../modules/Conch%3A%3ATime), and work around the bug in
[RT#125975](https://rt.cpan.org/Ticket/Display.html?id=125975).

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
