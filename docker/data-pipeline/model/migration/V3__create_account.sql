-- Entity: account, the business account a customer owns (company, currency and credit settings,
-- free-text notes). Indexed in Elasticsearch `accounts_connect`
-- (../elasticsearch/account_*.json, catalog ../catalog/account_field_catalog.json).
--
--   account_ref         identifier   full value only, case-sensitive: acct_7Q2M9K never finds acct_7Q2M9X
--   legal_name          company name name rules (case, accents, parts, any order, prefix >= 3, typos on
--                                    request) and legal suffixes (Ltd, GmbH, Inc, AB, ...) carry no weight:
--                                    GMBH KESTREL finds Kestrel Labs GmbH, ltd alone finds nothing
--   display_name        company name same rules as legal_name
--   aliases             alias        maintained by the account owner: NWT finds Northwind Traders Ltd only
--                                    because NWT is listed; never typo-corrected
--   country_code        fixed list   ISO 3166-1 alpha-2
--   base_currency       fixed list   ISO 4217, the currency the account trades in
--   credit_currency     fixed list   ISO 4217 of the credit limit, null = base_currency
--   credit_limit_minor  amount       minor units of credit_currency (cents; yen have none). BIGINT, not
--                                    NUMERIC: Debezium's default decimal.handling.mode=precise sends NUMERIC
--                                    as base64 bytes. An amount is never searched without its currency
--   payment_terms_days  amount       plain integer filter
--   status              fixed list   PENDING, ACTIVE, SUSPENDED, CLOSED (stored as the code itself)
--   notes               free text    English words in any order, word forms match (refund delay finds
--                                    "Refunds delayed"), stop words ignored, quoted phrases strict
--   opened_at           date         explicit range and time zone
CREATE TABLE IF NOT EXISTS inventory.accounts (
  id SERIAL NOT NULL PRIMARY KEY,
  account_ref VARCHAR(32) NOT NULL UNIQUE,
  owner_customer_id INT NOT NULL REFERENCES inventory.customers (id),
  legal_name VARCHAR(255) NOT NULL,
  display_name VARCHAR(255),
  aliases TEXT[],
  country_code VARCHAR(2) NOT NULL,
  base_currency VARCHAR(3) NOT NULL,
  credit_currency VARCHAR(3),
  credit_limit_minor BIGINT NOT NULL DEFAULT 0 CHECK (credit_limit_minor >= 0),
  payment_terms_days INT NOT NULL DEFAULT 30 CHECK (payment_terms_days >= 0),
  status VARCHAR(16) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACTIVE', 'SUSPENDED', 'CLOSED')),
  notes TEXT,
  opened_at TIMESTAMP NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF NOT (SELECT is_called FROM inventory.accounts_id_seq) THEN
    ALTER SEQUENCE inventory.accounts_id_seq RESTART WITH 50001;
  END IF;
END $$;

ALTER TABLE inventory.accounts REPLICA IDENTITY FULL;
