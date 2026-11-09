-- Accounts whose values exercise every search behavior of the account entity (see V3 and
-- ../tests/test_accounts_search.py). Owner found by email; inserted only when account_ref is missing.
--
--  Behavior                Stored                                        Finds                         Does not find
--  identifier              acct_7Q2M9K, acct_7Q2M9X (near twin)          acct_7Q2M9K (exactly 1)       acct_7Q2M9Z, acct_7q2m9k, acct_7Q2M
--  legal suffix            Northwind Traders Ltd, Kestrel Labs GmbH      traders northwind, GMBH KESTREL   ltd (alone)
--  possessive              Dante's Pizzeria S.r.l.                       dante, DANTE'S                dantes
--  alias (maintained)      Northwind Traders Ltd {NWT}, Meridian {MPS}   NWT, MPS                      NWX (no typo on aliases)
--  prefix (>= 3)           Meridian Pacific Shipping Ltd                 merid, merid pac              me
--  typo (opt-in)           Northwind, Kestrel, Meridian                  Nortwind, Northwnid, Kestral, Meridain   Northwxxx
--  English word forms      Refunds delayed while audits are running      refund delay, audit run       auditor (other word)
--                          Ordering paused until the warehouses reopen   order pause warehouse         orderly
--  over-stemming guard     Pipe organ restoration / Organic produce /    organ -> Willow only          organic, organization
--                          Organization restructured                     (keyword_marker keeps organic, organization whole)
--  phrase (strict)         Refunds delayed ...                           "refunds delayed"             "refund delay"
--  amount + currency       2,500.00 EUR / 2,500.00 SGD / 250.00 EUR      2,500.00 EUR -> Kestrel only  2500 (no currency)
--  credit currency         Lindqvist Design AB: base SEK, credit EUR     10,000.00 EUR
--  zero-decimal currency   Shanghai Lantern: credit 5,000,000 JPY        5,000,000 JPY (minor units = yen)
--  fixed list              status, base_currency                         frozen -> SUSPENDED, nok -> NOK   krone (DKK or NOK?), bitcoin
INSERT INTO inventory.accounts
  (account_ref, owner_customer_id, legal_name, display_name, aliases, country_code, base_currency,
   credit_currency, credit_limit_minor, payment_terms_days, status, notes, opened_at)
SELECT v.account_ref, c.id, v.legal_name, v.display_name, v.aliases::text[], v.country_code, v.base_currency,
       v.credit_currency, v.credit_limit_minor, v.payment_terms_days, v.status, v.notes, v.opened_at::timestamp
FROM (VALUES
  ('acct_7Q2M9K', 'tomasz.kowalski@example.pl', 'Northwind Traders Ltd', 'Northwind', '{NWT}', 'GB', 'GBP',
   null, 1500000, 30, 'ACTIVE', 'Refunds delayed while audits are running', '2023-05-02 09:00:00'),
  ('acct_7Q2M9X', 'alexandra.petrova@example.bg', 'Kestrel Labs GmbH', 'Kestrel', null, 'DE', 'EUR',
   null, 250000, 30, 'ACTIVE', 'Invoices disputed after the merger', '2024-01-15 09:00:00'),
  ('acct_K3S7R1', 'lars.berg-hansen@example.no', 'Meridian Pacific Shipping Ltd', 'Meridian Pacific', '{MPS}', 'SG', 'SGD',
   null, 250000, 45, 'ACTIVE', 'Ordering paused until the warehouses reopen', '2024-07-01 09:00:00'),
  ('acct_W1L0W5', 'marie-claire.dubois@example.fr', 'Willow Organ Builders SARL', 'Willow Organs', null, 'FR', 'EUR',
   null, 25000, 15, 'ACTIVE', 'Pipe organ restoration for two churches', '2024-03-20 09:00:00'),
  ('acct_GRN001', 'zoe.mueller@example.de', 'Greenleaf Organic Produce GmbH', null, null, 'DE', 'EUR',
   null, 0, 0, 'PENDING', 'Organic produce wholesaler, awaiting documents', '2025-01-15 09:00:00'),
  ('acct_OKF001', 'chidi.okafor@example.ng', 'Okafor & Sons Logistics Inc', 'Okafor Logistics', null, 'NG', 'USD',
   null, 500000, 30, 'SUSPENDED', 'Organization restructured last quarter, cards declined', '2025-05-08 09:00:00'),
  ('acct_DRU001', 'dante.russo@example.it', 'Dante''s Pizzeria S.r.l.', 'Dante''s', null, 'IT', 'EUR',
   null, 100000, 15, 'ACTIVE', 'Weekly flour orders', '2025-10-11 09:00:00'),
  ('acct_FJD001', 'Ola.Nordmann@Example.NO', 'Fjord Fisheries AS', null, null, 'NO', 'NOK',
   null, 7500000, 60, 'CLOSED', 'Account closed after the season', '2022-12-13 09:00:00'),
  ('acct_SLD001', 'soren.lindqvist@example.se', 'Lindqvist Design AB', null, null, 'SE', 'SEK',
   'EUR', 1000000, 30, 'ACTIVE', null, '2024-08-09 09:00:00'),
  ('acct_HBL001', 'kai_lee+invoices.2025@mailbox.example', 'Harbour Lights Cafe Pty Ltd', 'Harbour Lights', null, 'AU', 'AUD',
   null, 300000, 15, 'ACTIVE', 'Terminal rebooting during busy hours', '2025-02-03 09:00:00'),
  ('acct_SLT001', 'wei.li@example.cn', 'Shanghai Lantern Trading Co Ltd', null, '{SLT}', 'CN', 'CNY',
   'JPY', 5000000, 60, 'ACTIVE', 'Audit completed, the auditor requested statements', '2025-07-06 09:00:00')
) AS v (account_ref, owner_email, legal_name, display_name, aliases, country_code, base_currency,
        credit_currency, credit_limit_minor, payment_terms_days, status, notes, opened_at)
JOIN inventory.customers c ON c.email = v.owner_email
ON CONFLICT (account_ref) DO NOTHING;
