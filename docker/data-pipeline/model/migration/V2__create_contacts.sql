-- Entity: contact, one contact detail (email address or phone number) of a customer. Replaces the
-- former `phone_numbers` table: a customer has any number of emails and phones, each with a
-- label and a preferred flag. Indexed in Elasticsearch `contacts_connect`
-- (../elasticsearch/contact_*.json, catalog ../catalog/contact_field_catalog.json).
--
-- Lookup and discovery are two different tasks on the same value:
--   kind = EMAIL   lookup: full address, lowercased (Ola.Nordmann@Example.NO = ola.nordmann@example.no)
--                  discovery: whole fragments split on . _ + @ - (ola.nordmann, invoices 2025, mailbox)
--                  never: typo correction, dot removal, +tag removal (kai_lee@ is another address)
--   kind = PHONE   lookup: digits only, so spaces, dots, brackets, dashes and + do not matter
--                  discovery: last 4 digits, every matching contact is returned
--                  never: a guessed country or trunk prefix, partial numbers, typo correction
--   label          fixed list WORK, HOME, MOBILE, BILLING
-- A match on 4 digits is discovery, not proof of identity: results show the customer it belongs to.
CREATE TABLE IF NOT EXISTS inventory.contacts (
  id SERIAL NOT NULL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES inventory.customers (id) ON DELETE CASCADE,
  kind VARCHAR(8) NOT NULL CHECK (kind IN ('EMAIL', 'PHONE')),
  label VARCHAR(16) CHECK (label IN ('WORK', 'HOME', 'MOBILE', 'BILLING')),
  value VARCHAR(255) NOT NULL,            -- as typed by the user: display value, never rewritten
  preferred BOOLEAN NOT NULL DEFAULT false,
  verified_at TIMESTAMP,                  -- UTC, null while not verified
  UNIQUE (customer_id, kind, value)
);

DO $$
BEGIN
  IF NOT (SELECT is_called FROM inventory.contacts_id_seq) THEN
    ALTER SEQUENCE inventory.contacts_id_seq RESTART WITH 10001;
  END IF;
END $$;

ALTER TABLE inventory.contacts REPLICA IDENTITY FULL;
