BEGIN;

    -- Most of the time, we want to get validation results for given validation
    -- state IDs, rather than the other way around. This index provides us with
    -- a Index Only Scan for retrieving validation results for a validation state.
    create index on validation_state_member (validation_state_id);

COMMIT;

