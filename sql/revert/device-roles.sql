-- Revert conch:device-roles from pg

BEGIN;

DROP TABLE IF EXISTS device_role_services;
DROP TABLE IF EXISTS device_service;
DROP TABLE IF EXISTS device_role CASCADE;

COMMIT;
