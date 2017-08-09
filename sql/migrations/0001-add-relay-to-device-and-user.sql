BEGIN;

ALTER TABLE device ADD COLUMN seen_by_relay_id text
    REFERENCES relay (id);

ALTER TABLE device_report ADD COLUMN relay_id text
    REFERENCES relay (id);

CREATE TABLE relay_user (
  user_id      uuid           NOT NULL REFERENCES user_account (id),
  relay_id     text           NOT NULL REFERENCES relay (id),
  first_seen   timestamptz    NOT NULL DEFAULT current_timestamp,
  last_seen    timestamptz    NOT NULL DEFAULT current_timestamp,
  PRIMARY KEY (user_id, relay_id)
);

COMMIT;
