SELECT run_migration(181, $$

  -- this is only the INITIAL schema and is subject to change!
  insert into json_schema (type, name, version, created_user_id, body)
  values (
    'hardware_product', 'specification', 1,
    (select id from user_account where email = 'ether@joyent.com'),
'{
  "$schema" : "https://json-schema.org/draft/2019-09/schema",
  "description" : "describes the structure of the hardware_product.specification column -- the data used in json schemas to validate incoming device reports",
  "additionalProperties" : true,
  "properties" : {
    "chassis" : {
      "properties" : {
        "memory" : {
          "properties" : {
            "dimms" : {
              "$comment" : "items are in slot order, as in device report /dimms/*",
              "items" : {
                "properties" : {
                  "slot" : {
                    "$comment" : "compared to device report /dimms/*/memory-locator/memory-serial-number",
                    "type" : "string"
                  }
                },
                "type" : "object"
              },
              "minItems" : 1,
              "title" : "DIMMs",
              "type" : "array"
            }
          },
          "title" : "Memory",
          "type" : "object"
        }
      },
      "title" : "Chassis",
      "type" : "object"
    },
    "disk_size" : {
      "$comment" : "property names correspond to device report /disks/<disk serial>/model",
      "additionalProperties" : {
        "$comment" : "property values are compared to device report /disks/<disk serial>/block_sz",
        "title" : "Drive Model",
        "type" : "integer"
      },
      "required" : [
        "_default"
      ],
      "title" : "Disk Size",
      "type" : "object"
    }
  },
  "type" : "object"
}'
  );

$$);
