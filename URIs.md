# Conch Routes

## Status

### GET /ping
* Auth Required: No
* Response: `{ "status": "ok" }`

### GET /version
* Auth Required: No
* Response: `{ "version": version-string }`

## Authentication

### POST /login
* Auth Required: No
* Request: `input.yaml#Login`
* Response: `response.yaml#Login`

### POST /logout
* Auth Required: No
* Request: empty
* Response: 204 NO CONTENT

### POST /refresh_token
* Auth Required: Yes
* Request: empty
* Response: `response.yaml#Login`

## URL

### GET /user
* Auth Required: Yes
* Response: `response.yaml#UsersDetailed`

### POST /user
* Auth Required: Yes
* QueryParams:
    * send_invite_email BOOL
    * is_admin BOOL
* Request: `input.yaml#NewUser`
* Response: `response.yaml#User`

### POST /user/me/revoke
* Auth Required: yes
* Request: empty
* Response: 204 NO CONTENT

### GET /user/:target_user
* Auth Required: Yes
* Response: `response.yaml#UserDetailed`

### POST /user/:target_user/revoke
* Auth Required: yes
* Request: empty
* Response: 204 NO CONTENT

### DELETE /user/#target_user/password
* Auth Required: yes
* Response: 204 NO CONTENT

### DELETE /user/#target_user
* Auth Required: yes
* Response: 204 NO CONTENT

### GET /user/me/settings
* Auth Required: yes
* Response: application/json

### POST /user/me/settings
* Auth Required: yes
* Request: `application/json`
* Response: 200 OK but empty

### GET /user/me/settings/:key
* Auth Required: yes
* Response: application/json

### POST /user/me/settings/:key
* Auth Required: yes
* Response: 200 OK but empty

### DELETE /user/me/settings/#key
* Auth Required: yes
* Response: 204 NO CONTENT

### POST /user/me/password
* Auth Required: yes
* Request: `input.yaml#UserPassword`
* Response: 204 NO CONTENT

## Hardware Product

### GET /hardware_product
* Auth Required: yes
* Response: `response.yaml#HardwareProducts`

### GET /hardware_product/:hardware_product_id
* Auth Required: yes
* Response: `response.yaml#HardwareProduct`

### GET /db/hardware_product
* Auth Required: yes
### POST  /db/hardware_product
* Auth Required: yes
### POST  /db/hardware_product/:hardware_product_id
* Auth Required: yes
### DELETE /db/hardware_product/:hardware_product_id
* Auth Required: yes

## Hardware Vendor

### GET /hardware_vendor
* Auth Required: yes
* Response: `response.yaml#HardwareVendors`

### GET /hardware_vendor/:hardware_vendor_name
* Auth Required: yes
* Response: `response.yaml#HardwareVendor`

### POST /hardware_vendor/:hardware_vendor_name
* Auth Required: yes
* Request: empty
* Response: 303 => /hardware_vendor/:hardware_vendor_name

### DELETE /hardware_vendor/:hardware_vendor_name
* Auth Required: yes
* Response: 204 NO CONTENT

## Datacenter
### GET /dc
### POST /dc
### GET /dc/:datacenter_id
### POST /dc/:datacenter_id
### GET /dc/:datacenter_id/rooms
### DELETE /dc/:datacenter_id
* Auth Required: yes
* Response: 204 NO CONTENT

## Room
### GET /room
### POST /room
### GET /room/:datacenter_room_id_or_name
### POST /room/:datacenter_room_id_or_name
### GET /room/:datacenter_room_id_or_name/racks
### DELETE /room/:datacenter_room_id_or_name
* Auth Required: yes
* Response: 204 NO CONTENT

## Rack
### GET /rack_role
### POST /rack_role
### GET /rack_role/:rack_role_id_or_name
### POST /rack_role/:rack_role_id_or_name
### GET /rack
### POST /rack
### GET /rack/:datacenter_rack_id_or_name
### POST /rack/:datacenter_rack_id_or_name
### GET /rack/:datacenter_rack_id_or_name/layouts
### GET /layout
### POST /layout
### GET /layout/:layout_id
### POST /layout/:layout_id
### DELETE /layout/:layout_id
* Auth Required: yes
* Response: 204 NO CONTENT
### DELETE /rack_role/:rack_role_id_or_name
* Auth Required: yes
* Response: 204 NO CONTENT
### DELETE /rack/:datacenter_rack_id_or_name
* Auth Required: yes
* Response: 204 NO CONTENT

## Device
### POST /device/:device_id
### GET /device/:device_id
### POST /device/:device_id/graduate
### POST /device/:device_id/triton_setup
### POST /device/:device_id/triton_uuid
### POST /device/:device_id/triton_reboot
### POST /device/:device_id/asset_tag
### POST /device/:device_id/validated
### GET /device/:device_id/location
### POST /device/:device_id/location
### GET /device/:device_id/settings
### POST /device/:device_id/settings
### GET /device/:device_id/settings/:key
### POST /device/:device_id/settings/:key
### POST /device/:device_id/validation/:validation_id
### POST /device/:device_id/validation_plan/:validation_plan_id
### GET /device/:device_id/validation_state
### GET /device/:device_id/validation_result
### GET /device/:device_id/interface
### GET /device/:device_id/interface/:interface_name
### GET /device/:device_id/interface/:interface_name/:field
### DELETE /device/:device_id/location
* Auth Required: yes
* Response: 204 NO CONTENT
### DELETE /device/:device_id/settings/#key
* Auth Required: yes
* Response: 204 NO CONTENT

## Relay
### GET /relay
### POST /relay/:relay_id/register

## Workspace
### GET /workspace
### GET /workspace/:workspace_id
### GET /workspace/:workspace_id/child
### POST /workspace/:workspace_id/child
### GET /workspace/:workspace_id/device
### GET /workspace/:workspace_id/device/active -> /workspace/:workspace_id/device?t
### GET /workspace/:workspace_id/problem
### GET /workspace/:workspace_id/rack
### POST /workspace/:workspace_id/rack
### GET /workspace/:workspace_id/rack/:rack_id
### DELETE /workspace/:workspace_id/rack/:rack_id
* Auth Required: yes
* Response: 204 NO CONTENT
### POST /workspace/:workspace_id/rack/:rack_id/layout
### GET /workspace/:workspace_id/room
### PUT /workspace/:workspace_id/room
### GET /workspace/:workspace_id/relay
### GET /workspace/:workspace_id/user
### POST /workspace/:workspace_id/user
### DELETE /workspace/:workspace_id/user/#target_user
* Auth Required: yes
* Response: 204 NO CONTENT
### GET /workspace/:workspace/device-totals
* Response: `response.yaml#DeviceTotals`
            `response.yaml#DeviceTotalsCirconus`

## Legacy

### POST /reset_password (DEPRECATED)
* Auth Required: No
* Request: `{ "email": email }`
* Response: 301 -> `/user/email=:email/password`

### GET /doc (DEPRECATED)
* Auth Required: No
* Response: `public/doc/index.html`

