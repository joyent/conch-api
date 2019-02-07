BEGIN;
  ALTER TABLE datacenter_rack_layout ADD UNIQUE ( rack_id, ru_start );
COMMIT;
