BEGIN;

    -- Adjust user_account.email to NOT NULL
    ALTER TABLE user_account ALTER COLUMN email SET NOT NULL;

COMMIT;
