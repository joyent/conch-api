SELECT run_migration(1, $$

    CREATE TABLE device_relay_connection (
      device_id    text           NOT NULL REFERENCES device (id),
      relay_id     text           NOT NULL REFERENCES relay (id),
      first_seen   timestamptz    NOT NULL DEFAULT current_timestamp,
      last_seen    timestamptz    NOT NULL DEFAULT current_timestamp,
      PRIMARY KEY (device_id, relay_id)
    );

    CREATE TABLE user_relay_connection (
      user_id      uuid           NOT NULL REFERENCES user_account (id),
      relay_id     text           NOT NULL REFERENCES relay (id),
      first_seen   timestamptz    NOT NULL DEFAULT current_timestamp,
      last_seen    timestamptz    NOT NULL DEFAULT current_timestamp,
      PRIMARY KEY (user_id, relay_id)
    );

$$);
