# Conch

Database build and management service

# Setup

Conch uses `carton` to manage dependencies. Install `carton` and run `carton
install` or `make deps` in the `Conch/` directory.

# Endpoints

I am going to *strongly* recommend using [HTTPie](https://httpie.org) for
testing the endpoints in the command-line. Managing cookies and JSON encoding
with cURL is a pain, and HTTPie manages it well. All endpoint examples will be
done with HTTPie. The executable for HTTPie is `http`.

| Endpoint                        | Method | Auth       | Returns     | Description                                         |
| --------------------------      | ------ | ---------- | -------     | -----------                                         |
| `/login`                        | POST   | -          | Hash        | Create a login session                              |
| `/user`                         | POST   | admin      | Hash        | Create integrator users                             |
| `/datacenter_access`            | POST   | admin      | Hash        | Associate a user account with racks                 |
| `/relay`                        | GET    | admin      | Array       | List all Relay Devices                              |
| `/relay/:serial/register`       | POST   | integrator | Hash        | Register a Relay Device                             |
| `/device`                       | GET    | integrator | Array       | List all devices                                    |
| `/device/active`                | GET    | integrator | Array       | List all devices active in last 2 minutes           |
| `/device/health/FAIL`           | GET    | integrator | Array       | List all devices failing validation                 |
| `/device/health/PASS`           | GET    | integrator | Array       | List all devices passing validation                 |
| `/device/:serial`               | POST   | integrator | Hash        | Submit a device report for validation               |
| `/device/:serial`               | GET    | integrator | Hash        | Retrieve the most recent device report              |
| `/device/:serial/location`      | POST   | integrator | Hash        | Update a single device rack location                |
| `/device/:serial/location`      | DELETE | integrator | Hash        | Remove a single device from a rack location         |
| `/device/:serial/settings`      | GET    | integrator | Hash, Array | Retreive all device settings                        |
| `/device/:serial/settings`      | POST   | integrator | Hash        | Update or adds multipe settings for device          |
| `/device/:serial/settings/:key` | GET    | integrator | Hash        | Retreive single device setting identified by ':key' |
| `/device/:serial/settings/:key` | POST   | integrator | Hash        | Update or adds single setting for device            |
| `/rack`                         | GET    | integrator | Hash        | List all available racks                            |
| `/rack/:uuid`                   | GET    | integrator | Hash        | Get layout for a specific rack                      |
| `/rack/:uuid/layout`            | POST   | integrator | Hash        | Update multiple slots in a given rack               |
| `/problem`                      | GET    | integrator | Hash        | Describe all components failing validation          |

## Login

### Logging In

Sets up a session with appropriate priviledges for subsequent requests.
Sessions are referenced by a cookie, so the cookie will need to be stored and
used in following requests.

There is a special `admin` user that has the username `"admin"` with a
shared-secret password. The admin user has priviledges for endpoints a regular
user does not have.

* URL

  `/login`

* Methods

  `POST`

* Payload

  `{ "user": "$USER_NAME", "password": "$PASSWORD" }`

* Authorization

  None, as this provides the means to get authorization

* Success Response:

  * `200`

* Error Response:

  * `401 Unauthorized`

  `{ "error" : "failed login attempt" }`

  * `500`

  Big catch-all for now. Something went wrong. Check the logs.

* Example request

  ```
  http POST :5000/login --session admin_session <<EOF
  { "user" : "admin", "password": "hunter2" }
  EOF
  ```
## Relays

### Retrieving all registered relays

* URL

  `/relay`

* Methods

  `GET`

* Authorization

Requires an admin account.

### Registering a relay

Registration doubles with heartbeating (using the `updated` field.)

* URL

  `/relay/:serial/register`

* Methods

  `POST`

* Authorization

Requires an integrator account.

* Payload

A JSON blob containing the image version and the SSH port of the reverse tunnel
service on the Relay.

* Example

```
http POST :5000/relay/000000003d1d1c36/register $SESSION <<EOF
{
  "version": "0.1",
  "ssh_port": 26432
}
EOF
```

## Devices

### List all account accessible devices

* URL

  `/device`

* Methods

  `GET`

* Authorization

  Requires an integrator account.

* Example

```
http :5000/device --session integrator
```

### List active devices

List all devices on your account that have reported in the last two minutes.

* URL

  `/device/active`

* Method

  `GET`

* Authorization

  Requires an integrator account.

* Example

```
http :5000/device --session integrator
```

### List all device failing validation

* URL

  `/device/health/FAIL`

### List all devices passing validation

* URL

  `/device/health/PASS`

### Creating device report

Takes a JSON blob created by `export.pl` and processes it.

* URL

  `/device/:serial`

* Methods

  `POST`

* Payload

  JSON blob generated by `export.pl`

* Authorization

  Requires integrator account and session.

* Success Response:

  * `200`

* Error Response:

  * `500`

  Big catch-all for now. Something went wrong. Check the logs

* Example request

  ```
  http POST :5000//device/A8CD3FG < report_from_HB.json
  ```

### Retrieving device inventory and validation report

Takes a device serial number and responds with a JSON object containing the
device attributes, the latest device report (object key `latest_report`) and
the validations run from that report (object key `validations`).

* URL

  `/device/:serial`

* Methods

  `GET`

* Authorization

  Requires integrator account and session.

* Success Response:

  * `200`

* Error Response:

  * `401`

  Unauthorized or device does not exist.

* Example request

  ```
  http :5000/device/45M2ND2 --session account
  ```

## Updating device location

Takes a serial number, the rack UUID, and the rack slot.

If the device does not yet exist, will create a stub entry in the device table.

Will not let you clobber an occupied slot, and verifies that the slot you want to use exists.

* URL

  `/device/:serial/location`



 `POST`

* Authorization

  Requires integrator account and session.

* Success Response:

  * `200`

* Error Response:

  * `401`

  Unauthorized or device does not exist.

  * `500`

  Something went wrong while trying to update the record. See the logs.

* Example request

  ```
  http :5000/device/45M2ND2/location --session account <<EOF
  { "device": "$SERIAL", "rack": "$RACK_UUID", "rack_unit": "$RACK_UNIT" }
  EOF
  ```

### Removing a device from a rack slot

Takes a serial number, rack UUID, and rack slot.

* URL

  `/device/:serial/location`

* Methods

  `DELETE`

* Authorization

  Requires integrator account.

* Example request

  ```
  http DELETE :5000/device/45M2ND2/location --session account <<EOF
  { "device": "$SERIAL", "rack": "$RACK_UUID", "rack_unit": "$RACK_UNIT" }
  EOF
  ```

## Racks

### Retrieving available racks

* URL

  * `/rack`

### Retrieve layout for specific rack

Includes the device object as key `occupant`, if assigned.

* URL

  * `/rack/:uuid`

### Bulk updating a rack layout

Returns `updated` and `errors` arrays.

* URL

  `/rack/:uuid/layout`

* Method

  `POST`


Takes a JSON blob in the form

```
{
  "$SERIAL": $RACK_UNIT,
  "$SERIAL": $RACK_UNIT,
  "$SERIAL": $RACK_UNIT
}
```

* Example request

```
http POST :5000/7d7665d3-9244-42d6-bad8-f9505a9380ae/layout --session account <<EOF
{
  "BAENG1O": 3,
  "45M2ND2": 1
}
EOF
```

## User

### Creating integrator user

Creates a new integrator user with a randomly generated 8-digit password.

* URL

  `/user`

* Methods

  `POST`

* Payload

  `{ "user" : "$NEW_USER_NAME" }`

* Authorization

  Requires logged-in admin

* Success Response:

  * `201 Created`

  `{ "user": "${new user name}", "password": "${generated password}" }`

* Error Response:

  * `401 Unauthorized`

  Unauthorized. Log in as admin first

  * `500`

  Big catch-all for now. Something went wrong. Check the logs.

* Example request

  ```
  http POST :5000/user --session admin_session <<EOF
  { "user" : "some_integrator_username" }
  EOF
  ```

### Setting user datacenter access

Set the access permissions for a set of users for a set a datacenter rooms.

**NOTE:** Without BHDA access, I decided to use AZs as identifiers for the
datacenter rooms. We need a unique value that can identify a datacenter room.
We could also use the vendor name, but that's null-able. AZs are not unique, so
we could have multiple datacenter rooms with the same AZ (is this desired?).

* URL

  `/datacenter_access`

* Methods

  `PUT`

  This is an idempotent operation, so it is a **PUT** request rather than POST.

* Payload

  The payload is a JSON object with user names as keys, an a list of AZ names as values.

  ```
  { "${INTEGRATOR_NAME}" : ["${DATACENTER_ROOM_AZ}", ... ]}
  ...
  }
  ```

  **NOTE:** You can remote all user access by associating a list with
  non-existing datacenter names. e.g., `{ "no_access_user" : ["__NO_ACCESS__"] }`.
  Ideally, you could set this with a empty list, but because of how Perl
  handles hashes, this is a bug for now.

* Authorization

  Requires logged-in admin

* Success Response:

  * `200 Created`

  No payload in response.


* Error Response:

  * `401 Unauthorized`

  Unauthorized. Log in as admin first

  * `500`

  Big catch-all for now. Something went wrong. Check the logs.

* Example request

  ```
  http PUT :5000/datacenter_access --session admin_session <<EOF
  { "integrator_1234" : ["ap-southeast-1a"] }
  EOF
  ```

## Devices

### Listing integrator accessible devices

List all of the devices a given integrator has premissioned access for, as
granted by `PUT /datacenter_access`.

* URL

  `/device`

* Methods

  `GET`

* Authorization

  Requires logged-in **integrator** user. Currently, an admin does not have
  access to this endpoint (we need to decide how this should be used by an
  admin).

* Success Response:

  * `200 Created`

  `{ "devices": [...list of devices...] }`

* Error Response:

  * `401 Unauthorized`

  Unauthorized. Log in as an integrator first

  * `500`

  Big catch-all for now. Something went wrong. Check the logs.

* Example request

  ```
  http :5000/user --session integrator_session
  ```

### Device settings

#### List all device settings

List all of current settings for a device. List only the names of the setting
keys if given the query parameter `keys_only`.

* URL

  `/device/:serial/settings[?keys_only=1]`

* Methods

  `GET`

* Authorization

  Requires logged-in **integrator** user. Currently, an admin does not have
  access to this endpoint (we need to decide how this should be used by an
  admin).

* Success Response:

  * `200 OK`

  ```
    {
        "bmc_fw": "2.43.43.43",
         "exp_fw": "4.32",
        "system_bios": "2.4.3"
    }

  ```

  * `200 OK` (with `keys_only` set to true)

  ```
    [
        "bmc_fw", "exp_fw", "system_bios"
    ]

  ```

* Error Response:

  * `401 Unauthorized`

  Unauthorized. Log in as an integrator first

  * `500`

  Big catch-all for now. Something went wrong. Check the logs.

* Example request

  ```
  http preflight.scloude.zone/device/BAENG1O/settings --session integrator_session
  ```

#### Set or update multiple device settings


* URL

  `/device/:serial/settings`

* Methods

  `POST`

* Authorization

  Requires logged-in **integrator** user. Currently, an admin does not have
  access to this endpoint (we need to decide how this should be used by an
  admin).

* Success Response:

  * `200 OK`

  ```
    {
        "status": "updated settings for BAENG1O"
    }

  ```

* Error Response:

  * `401 Unauthorized`

  Unauthorized. Log in as an integrator first

  * `500`

  Big catch-all for now. Something went wrong. Check the logs.

* Example request

  ```
  http preflight.scloud.zone/device/BAENG1O/settings --session integrator_session <<EOF
  {
      "system_bios" : "2.4.3",
      "exp_fw" : "4.32",
      "bmc_fw" : "2.43.43.43"
  }
  EOF
  ```

#### Get single device setting

Get an object with the value of the single specified setting.

* URL

  `/device/:serial/settings/:key`

* Methods

  `GET`

* Authorization

  Requires logged-in **integrator** user. Currently, an admin does not have
  access to this endpoint (we need to decide how this should be used by an
  admin).

* Success Response:

  * `200 OK`

  ```
    {
        "bmc_fw": "2.43.43.43",
    }

  ```

* Error Response:

  * `401 Unauthorized`

  Unauthorized. Log in as an integrator first

  * `404 Not Found`

  The requested key is not set for this device.

  * `500`

  Big catch-all for now. Something went wrong. Check the logs.

* Example request

  ```
  http preflight.scloude.zone/device/BAENG1O/settings/bmc_fw --session integrator_session
  ```

#### Set single device setting value


* URL

  `/device/:serial/settings/:key`

* Methods

  `POST`

* Authorization

  Requires logged-in **integrator** user. Currently, an admin does not have
  access to this endpoint (we need to decide how this should be used by an
  admin).

* Success Response:

  * `200 OK`

  ```
    {
        "status": "updated setting 'bmc_fw' for BAENG1O"
    }

  ```

* Error Response:

  * `401 Unauthorized`

  Unauthorized. Log in as an integrator first

  * `500`

  Big catch-all for now. Something went wrong. Check the logs.

* Example request

  ```
  http preflight.scloud.zone/device/BAENG1O/settings/bmc_fw --session integrator_session <<EOF
  {
      "bmc_fw" : "2.43.43.43"
  }
  EOF
  ```

## Problems

### Listing all problems for integrator devices

Get a JSON object that describes all problems in the last Device Validation
Report for devices assigned to an integrator account.

Device Reports and their associated Validation Criteria are not heavily
normalized, so a long of munging is probably going to be required. As some
point, all tests associated with a device should have definitions in the
`device_validation_criteria` table, with associated log messages and
remediation steps. Big TODO here.

We try to return as much useful context for a given problem as possible, including:

* Device location
* Datacenter information
* Rack information
* Array of problems
* Validation criteria for each problem (if it exists)

* URL

  `/problem`

* Methods

  `GET`

* Authorization

  Requires integrator account.

* Success Response:

  * `200`

```
{
    "BAENG1O": {
        "datacenter": {
            "id": "f465c98a-85f5-4540-9a78-acee9aa87ba7",
            "name": "arcadia-planitia-1a"
        },
        "health": "FAIL",
        "problems": [
            {
                "component_id": "3b26f301-d7b8-454f-bf0a-e8d0b5d29d2b",
                "component_name": "BTHC640407461P6PGN",
                "component_type": "SATA_SSD",
                "criteria": {
                    "component": "SAS_SSD",
                    "condition": "temp",
                    "crit": 51,
                    "id": "317b20f4-522c-4b37-b06d-7419a47bc535",
                    "min": 25,
                    "warn": 41
                },
                "log": "CRITICAL: BTHC640407461P6PGN: 75 (>51)",
                "metric": 75
            },
            {
                "component_id": "b2cb730f-d58b-4d2c-b21d-6b768b3aba38",
                "component_name": "BTHC640405WM1P6PGN",
                "component_type": "SATA_SSD",
                "criteria": {
                    "component": "SAS_SSD",
                    "condition": "temp",
                    "crit": 51,
                    "id": "317b20f4-522c-4b37-b06d-7419a47bc535",
                    "min": 25,
                    "warn": 41
                },
                "log": "CRITICAL: BTHC640405WM1P6PGN: 100 (>51)",
                "metric": 100
            }
        ],
        "rack": {
            "id": "7d7665d3-9244-42d6-bad8-f9505a9380ae",
            "name": "A01",
            "role": "TRITON",
            "unit": 3
        }
    }
}
```

* Example request

  ```
  http :5000/problem --session integrator_session
  ```
