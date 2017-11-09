# 2017-11-02
# Creating workspaces and users with API


Until the UI for creating new workspaces and inviting users is implemented, we
can use these APIs to do so.

I'm going to use HTTPie (`http`) here, because you'll need to store cookies.
Feel free to use cURL if that floats your boat.

All commands presume you're already authenticated and have a session set up. To
do so

```
http https://preflight.scloud.zone/login --session joyent_session <<EOF
{ "user" : "$user_name", "password": "$password" }
EOF
```


## Creating a Sub-Workspace

First, you need to the workspace ID for the workspace from which you'll want to
make a sub-workspace. In this example, we'll create a sub-workspace of the
global workspace.

```
http POST https://preflight.scloud.zone/workspace --session joyent_session
HTTP/1.1 200 OK
...

[
    {
        "description": "Global workspace. Ancestor of all workspaces.",
        "id": "496f76b4-8245-4d41-8d97-42fe988401c5",
        "name": "GLOBAL",
        "role": "Administrator"
    },
   ... list of other workspaces ...
]
```

We can list the datacenter rooms assigned to the workspace. For the Global
zone, this will include all datacenter rooms.

```

http https://preflight.scloud.zone/workspace/496f76b4-8245-4d41-8d97-42fe988401c5/room \
   --session joyent_session

HTTP/1.1 200 OK
...
[
    {
        "alias": "AZ1",
        "az": "arcadia-planitia-1a",
        "id": "419876f1-f7f9-4cf3-8895-2f3683c03a1e",
        "vendor_name": "MARS1.1"
    },
    ...
]
```

We will now create a new sub-workspace. Sub-workspaces have no assigned
datacenter rooms upon creation and must be added afterwards.

```
http POST https://preflight.scloud.zone/workspace/496f76b4-8245-4d41-8d97-42fe988401c5/child \
   --session joyent_session <<EOF
{
    "name" : "subworkspace_name",
    "description" : "Longer description of the purpose of this workspace"
}
EOF

HTTP/1.1 200 OK
...
[
    {
        "description": "Longer description of the purpose of this workspace",
        "id": "00ec51aa-df1e-4f99-8c45-e0d61dfe6729",
        "name": "subworkspace_name",
        "role": "Administrator"
    },
    ...
]
```

Modifying the datacenter rooms assigned to a workspace is an idempotent
**REPLACEMENT** operation (hence `PUT`!). If you wish to add a new datacenter
room to an existing list of rooms, *you must include all previously added
datacenter rooms in the request*.

```
http PUT https://preflight.scloud.zone/workspace/496f76b4-8245-4d41-8d97-42fe988401c5/room \
   --session joyent_session <<EOF
[ "419876f1-f7f9-4cf3-8895-2f3683c03a1e", ... other DC room IDs... ]
EOF

HTTP/1.1 200 OK
...
[
    {
        "alias": "AZ1",
        "az": "arcadia-planitia-1a",
        "id": "419876f1-f7f9-4cf3-8895-2f3683c03a1e",
        "vendor_name": "MARS1.1"
    },
    ... other DC rooms ...
]
```

Sub-workspace created and datacenter rooms added!

## Inviting users

Users are given access to a workspace through _invitations_ specified by email
address. If a user doesn't exist, an account will be created. If a user already
exists, their account will be given access.

**NOTE**: Switching between a user's available workspaces in the UI hasn't been
added yet. API access only for multiple workspaces.

**NOTE**: If a user does not exist yet, a digits-only password is generated and
given in the response. This is temporary. This will be replaced with a system
that sends a user an email invite with a link with a one-time token. They will
use that link to assign a password of their choosing.

```
http POST https://preflight.scloud.zone/workspace/496f76b4-8245-4d41-8d97-42fe988401c5/user \
   --session joyent_session <<EOF
{ "email" : "new_user@joyent.com",
  "role" : "Administrator"
}
EOF

HTTP/1.1 200 OK
...
{
    "email": "new_user@joyent.com",
    "name": "new_user@joyent.com",
    "password": "12341234",
    "role": "Administrator"
}
```

`email` is the user's email address and `name` is the **user name the user will
use to login**. By default, these are the same value, but may be different.

Available role values are: "Administrator", "Read-only", "Integrator", "DC
Operations", and "Integrator Manager". The available roles will be described by
`GET /role` once the Workspace UI is implemented.


You can list all users who are members of a workspace.

```
http https://preflight.scloud.zone/workspace/496f76b4-8245-4d41-8d97-42fe988401c5/user \
   --session joyent_session

HTTP/1.1 200 OK
...
[
    {
        "email": "new_user@joyent.com",
        "name": "new_user@joyent.com",
        "role": "Administrator"
    },
    {
        "email": "build-ops@joyent.com",
        "name": "joyent",
        "role": "Administrator"
    }
]
```
