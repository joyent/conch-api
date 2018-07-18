# 2017-11-02
# Validation Use Cases


## Existent Use Cases

These validation cases exist in the code base as of 2017-11-02;

1. Validation based solely on the information available in the report, such
   as product name, temperature, etc.

2. Validation based on the current location of the device reporting and
   information available in the report.

    * For example, the reported switch peer ports is validated against an
      expected value calculated by the rack slot a device has been assigned.

    * Similarly, as the device role is determined by the rack layout,
      validating the number of disks is determined by the location.

3. There are two distinct groups of validations that can be applied to a
   device. Which validations are applied is based on whether a device reports
   that is a "switch" or not.

4. Certain validations are applied only if the necessary information is present
   in the report.

    * Disk Temperature, number of disks, and NIC configurations are validated
      only if the information is present in the report.

    * CPU temperature, product and system details, and the number of NICs are
      validated every time.

    * Device reports will be rejected as unparsable if the necessary
      information is not present.


## Proposed Use Cases and Ideas

1. The set of validations should be configurable per-workspace. This will allow
   a workspace for integrators to have different validations than a workspace
   for DC ops, for instance.

2. Validations should be parameterizable per-workspace, including disabling
   individual validations.

3. Validations should be be applied based on the stage of the datacenter build.
   The validations that should be applied during integration might be different
   from when racks are loaded in the DC.

    * This could be achieved with separate workspaces as mentioned in #1. You
      would have an 'Integration' workspace and a 'DC Build' workspace. Is this
      more or less confusing than stages?

4. Validations might be grouped into a logical sets. This helps organize
   validations, and might be more straightforward for users to apply the same
   set validations across multiple workspaces.

5. A set of validations are applied to new workspaces by default. One proposed
   method is for a sub-workspace to inherit the validations used by the parent
   workspace.

    * "I own a workspace and have assigned contractors to sub-workspaces. I want
       those subs to run my validations always but allow them to add on their own
       in their subs" https://chat.joyent.us/joyent/pl/dbdwup88tbb4xfufy1zeub1dyo

    * If a validation set is changed, do we propagate the change to all
      inheriting workspaces?

6. Given #5, sub-workspace should be able to modify the parameters or disable
   validations of the inherited validation set.

   * If the validation set is changed in the parent workspace, does it
     overwrite any validation modifications made by the sub-workspace?


7. The idea of validation _templates_ has also been floated as an alternative
   to validation inheritance.  Rather than inheriting validations from the
   parent workspace, as in #5 and #6, each workspace maintains separate sets of
   validations and we make it easy to create a set of validations from a
   collection of templates.

8. Validations results should be published as soon as they are gathered. We
   will publish a live update of the results to the UI or other subscribers.

9. We should be able to show the progress of a given device is in the
   validation process. If a device has _x_ validations, we can calculated
   number _y_ of validations that have been completed.

10. Validations can be performed by external processes that have no access to
    the database. These processes may be invoked as callbacks or through
    messages published through listening sockets, and we are able to associate
    the results of these external validations with the validation process.

11. Validations sets may depended on other validation sets. Validation
    set _B_ may require that all validations in validation _A_ pass before it
    performs its own validations ("cascading validations"). For example, a set
    of validations that perform checks of disk performance should only be
    performed if the validation set that checks the existence and health status
    of the disks.

12. Validations should timeout after a pre-determined amount of time.
