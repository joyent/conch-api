# NAME

conch

# DESCRIPTION

Start script for conch Mojo app

# SYNOPSIS

See `bin/conch --help` for full usage.

Usage: APPLICATION COMMAND \[OPTIONS\]

Conch-specific commands are:

- [check\_layouts](../modules/Conch::Command::check_layouts)

    Check for conflicts in existing rack layouts

- [check\_validation\_plans](../modules/Conch::Command::check_validation_plans)

    check all validations and validation plans

- [check\_workspace\_racks](../modules/Conch::Command::check_workspace_racks)

    verify the integrity of all workspace\_rack rows

- [clean\_roles](../modules/Conch::Command::clean_roles)

    Clean up unnecessary user\_workspace\_role entries

- [create\_token](../modules/Conch::Command::create_token)

    Create a new application token

- [create\_user](../modules/Conch::Command::create_user)

    Create a new user

- [merge\_validation\_results](../modules/Conch::Command::merge_validation_results)

    Collapse duplicate validation\_result rows together

- [thin\_device\_reports](../modules/Conch::Command::thin_device_reports)

    remove unwanted device reports

- [update\_validation\_plans](../modules/Conch::Command::update_validation_plans)

    bring validation\_plans up to date with new versions of all validations

- [workspaces](../modules/Conch::Command::workspaces)

    View all workspaces in their heirarchical order

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/).
