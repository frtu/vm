-- Entity: customer, a person. Indexed in Elasticsearch `customers_connect`
-- (../elasticsearch/customer_*.json, catalog ../catalog/customer_field_catalog.json).
--
-- Also run by ../../db/init/10-init-model.sh on the first start of an empty database.
-- The first columns (first_name ... registered_at) are read by the Flink job flink-cdc-es
-- (class Customer): keep them as they are. Created only when missing (no DROP), later columns
-- added with ADD COLUMN IF NOT EXISTS, so every statement is idempotent.
--
-- Search behavior follows what a column means, not its SQL type:
--   customer_ref   identifier    full value only, case-sensitive, never typo-corrected, no partial
--   first_name,    person name   case and accents ignored (zoe finds Zoë), hyphen / apostrophe parts
--   last_name                    (claire finds Marie-Claire, arcy finds D'Arcy, but marieclaire and darcy
--                                do not), any word order, prefixes from 3 characters (alex), typos only
--                                on request (1 edit from 3 characters: Kowalsky). No nicknames
--   email          contact       exact lookup after lowercasing, or discovery by whole fragments split on
--                                . _ + @ - ; no typo, no removal of dots or +tags
--   phone          contact       exact lookup on digits only, or last 4 digits; the country code is part of
--                                the value (+61 2 9374 4000 is not 02 9374 4000)
--   street         address line  name rules, no typo
--   zip            identifier    exact
--   city           label         exact filter and facet
--   country_code   fixed list    ISO 3166-1 alpha-2, resolved from the user's words before the search
--   status         fixed list    0 PENDING, 1 ACTIVE, 2 SUSPENDED, 3 CLOSED (label set by the ingest pipeline)
--   registered_at  date          explicit range and time zone; 05/07/2025 is clarified, never guessed
CREATE SCHEMA IF NOT EXISTS inventory;

CREATE TABLE IF NOT EXISTS inventory.customers (
  id SERIAL NOT NULL PRIMARY KEY,
  first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,  -- primary email; more addresses in inventory.contacts
  street VARCHAR(255),
  zip VARCHAR(255),
  city VARCHAR(255),
  phone VARCHAR(255),                  -- primary phone, as typed (display value)
  status INT,                          -- fixed list, see above
  registered_at TIMESTAMP              -- UTC; Debezium sends microseconds since epoch
);

ALTER TABLE inventory.customers
  ADD COLUMN IF NOT EXISTS customer_ref VARCHAR(32),  -- public reference shown to users (cus_...)
  ADD COLUMN IF NOT EXISTS country_code VARCHAR(2);   -- ISO 3166-1 alpha-2

-- rows created before customer_ref existed get a reference derived from their id
UPDATE inventory.customers SET customer_ref = 'cus_' || id WHERE customer_ref IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS customers_customer_ref_key ON inventory.customers (customer_ref);

-- first id 1001, only while the sequence was never used (new table)
DO $$
BEGIN
  IF NOT (SELECT is_called FROM inventory.customers_id_seq) THEN
    ALTER SEQUENCE inventory.customers_id_seq RESTART WITH 1001;
  END IF;
END $$;

-- full `before` row in Debezium update / delete events
ALTER TABLE inventory.customers REPLICA IDENTITY FULL;
