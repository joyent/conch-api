# NAME

Conch::ValidationError - Internal error representation for Conch::Validation

# DESCRIPTION

Extends [Mojo::Exception](https://metacpan.org/pod/Mojo::Exception) to store a `hint` attribute. Intended for use in
[Conch::Validation](/modules/Conch::Validation).

# METHODS

## error\_loc

Return a description of where the error occurred. Provides the module name and
line number, but not the filepath, so it doesn't expose where the file lives.

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
