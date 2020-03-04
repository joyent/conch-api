# NAME

Conch::UUID - Functions for working with UUIDs in Conch

# SYNOPSIS

```perl
use Conch::UUID 'is_uuid';
```

# DESCRIPTION

Currently exports a single function, `is_uuid`, to determine whether a string
is in the UUID format. It uses the format specified in RFC 4122
https://tools.ietf.org/html/rfc4122#section-3

```
  UUID                   = time-low "-" time-mid "-"
                           time-high-and-version "-"
                           clock-seq-and-reserved
                           clock-seq-low "-" node
  time-low               = 4hexOctet
  time-mid               = 2hexOctet
  time-high-and-version  = 2hexOctet
  clock-seq-and-reserved = hexOctet
  clock-seq-low          = hexOctet
  node                   = 6hexOctet
  hexOctet               = hexDigit hexDigit
  hexDigit =
        "0" / "1" / "2" / "3" / "4" / "5" / "6" / "7" / "8" / "9" /
        "a" / "b" / "c" / "d" / "e" / "f" /
        "A" / "B" / "C" / "D" / "E" / "F"
```

UUID version and variant ('reserved') hex digit standards are ignored.

# FUNCTIONS

## is\_uuid

Return a true or false value based on whether a string is a formatted as a UUID.

```
if (is_uuid('D8DC809C-935E-41B8-9E5F-B356A6BFBCA1')) {...}
if (not is_uuid('BAD-ID')) {...}
```

Case insensitive.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
