-- Same tables as ../../../db/init/10-create_inventory.sql, without the DROP: a table is created
-- only when missing, so it's safe on a database already initialized by db/init.
-- inventory.customers is indexed in Elasticsearch `customers_connect`
-- (mapping: ../elasticsearch/customer_index_template.json). Keep both aligned.
CREATE SCHEMA IF NOT EXISTS inventory;

CREATE TABLE IF NOT EXISTS inventory.customers (
  id SERIAL NOT NULL PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  street VARCHAR(255),
  zip VARCHAR(255),
  city VARCHAR(255),
  phone VARCHAR(255),
  status INT,
  registered TIMESTAMP
);

CREATE TABLE IF NOT EXISTS inventory.phone_numbers (
  id SERIAL NOT NULL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES inventory.customers (id),
  preferred BOOLEAN,
  value VARCHAR(255)
);

-- first ids 1001 / 10001, only while a sequence was never used (new table)
DO $$
BEGIN
  IF NOT (SELECT is_called FROM inventory.customers_id_seq) THEN
    ALTER SEQUENCE inventory.customers_id_seq RESTART WITH 1001;
  END IF;
  IF NOT (SELECT is_called FROM inventory.phone_numbers_id_seq) THEN
    ALTER SEQUENCE inventory.phone_numbers_id_seq RESTART WITH 10001;
  END IF;
END $$;

-- full `before` row in Debezium update / delete events
ALTER TABLE inventory.customers REPLICA IDENTITY FULL;
ALTER TABLE inventory.phone_numbers REPLICA IDENTITY FULL;
