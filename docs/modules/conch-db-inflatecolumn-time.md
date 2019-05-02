# DESCRIPTION

Automatically inflates/deflates timestamps in the database to Conch::Time objects (which
is a subclass of Time::Moment).

No extra work needs to be done for deflation, because postgres is happy to accept our slight
modifications to the format used in `to_string`.  All we need to do is rebless the
Time::Moment object into Conch::Time, and work around the bug in RT#125975.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
