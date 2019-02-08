-- Revert conch:drop-run-migrations from pg

BEGIN;

DO $$
BEGIN
    -- if you wish to revert past this point comment out the following exception
    RAISE EXCEPTION 'Reverting after this point is dangerous.';
END $$;

COMMIT;
