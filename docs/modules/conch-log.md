# Conch::Log

Enhanced Mojo logger that logs with file path, and caller data using the Bunyan
log format

See also: Mojo::Log, Mojo::Log::More, and node-bunyan

# SYNOPSIS

```
$app->log(Conch::Log->new)
```

# METHODS

## debug

## info

## warn

## error

## fatal

## raw

See [Conch::Plugin::Logger](https://metacpan.org/pod/Conch::Plugin::Logger) for a use case of `raw`

# LICENSING

Based on Mojo::Log::More : https://metacpan.org/pod/Mojo::Log::More

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
