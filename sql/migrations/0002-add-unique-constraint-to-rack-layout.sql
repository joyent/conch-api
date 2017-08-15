SELECT run_migration(2, $$
  ALTER TABLE datacenter_rack_layout ADD UNIQUE ( rack_id, ru_start );
$$);
