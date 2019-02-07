-- Revert conch:user-session-token from pg

BEGIN;

DROP TABLE IF EXISTS user_session_token;

COMMIT;
