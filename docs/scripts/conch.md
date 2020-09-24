# conch

## SOURCE

[https://github.com/joyent/conch/blob/master/bin/conch](https://github.com/joyent/conch/blob/master/bin/conch)

## DESCRIPTION

Start script for conch Mojo app

## SYNOPSIS

See `bin/conch --help` for full usage.

Usage: APPLICATION COMMAND \[OPTIONS\]

Conch-specific commands are:

- [check\_layouts](../modules/Conch%3A%3ACommand%3A%3Acheck_layouts)

    Check for conflicts in existing rack layouts

- [check\_validation\_plans](../modules/Conch%3A%3ACommand%3A%3Acheck_validation_plans)

    check all validations and validation plans

- [check\_workspace\_racks](../modules/Conch%3A%3ACommand%3A%3Acheck_workspace_racks)

    verify the integrity of all workspace\_rack rows

- [clean\_roles](../modules/Conch%3A%3ACommand%3A%3Aclean_roles)

    Clean up unnecessary user\_workspace\_role entries

- [copy\_user\_data](../modules/Conch%3A%3ACommand%3A%3Acopy_user_data)

    Copy user records and authentication tokens between databases

- [create\_token](../modules/Conch%3A%3ACommand%3A%3Acreate_token)

    Create a new application token

- [create\_user](../modules/Conch%3A%3ACommand%3A%3Acreate_user)

    Create a new user

- [fix\_usernames](../modules/Conch%3A%3ACommand%3A%3Afix_usernames)

    fixes Joyent usernames so they are not the same as the email

- [force\_password\_change](../modules/Conch%3A%3ACommand%3A%3Aforce_password_change)

    force a user (or by default, all users) to change their password

- [new\_organizations](../modules/Conch%3A%3ACommand%3A%3Anew_organizations)

    create new organization data

- [passwd](../modules/Conch%3A%3ACommand%3A%3Apasswd)

    Change a user's password

- [thin\_device\_reports](../modules/Conch%3A%3ACommand%3A%3Athin_device_reports)

    remove unwanted device reports

- [update\_validation\_plans](../modules/Conch%3A%3ACommand%3A%3Aupdate_validation_plans)

    bring validation\_plans up to date with new versions of all validations

- [workspace\_to\_build](../modules/Conch%3A%3ACommand%3A%3Aworkspace_to_build)

    convert workspace content to a build

- [workspaces](../modules/Conch%3A%3ACommand%3A%3Aworkspaces)

    View all workspaces in their heirarchical order

## LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at [https://www.mozilla.org/en-US/MPL/2.0/](https://www.mozilla.org/en-US/MPL/2.0/).
