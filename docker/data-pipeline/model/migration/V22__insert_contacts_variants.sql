-- Contacts whose values exercise the lookup / discovery split (see V2 and
-- ../tests/test_contacts_search.py). Customer found by email; inserted only when missing.
--
--  Behavior               Stored                                     Finds                          Does not find
--  email lookup           Ola.Nordmann@Example.NO                    OLA.NORDMANN@example.no        olanordmann@example.no
--  email +tag             kai_lee+invoices.2025@mailbox.example      (full address only)            kai_lee@mailbox.example
--  email fragments        a.petrova@northwind-traders.example        northwind traders, petrova     northwindtraders
--  phone formatting       (415) 555-0123                             415.555.0123, (415)5550123     555-0123 (partial)
--  phone country/trunk    +61 2 9374 4000                            +61 (2) 9374-4000              02 9374 4000
--  last 4 digits          (415) 555-0123, +44 161 496 0123           0123 -> both contacts          (no identity proof)
--  shared number          (800) 555-2100 (Brandon and Sarah, V12)    800 555 2100 -> both customers
INSERT INTO inventory.contacts (customer_id, kind, label, value, preferred, verified_at)
SELECT c.id, v.kind, v.label, v.value, v.preferred, v.verified_at::timestamp
FROM (VALUES
  ('Ola.Nordmann@Example.NO',               'EMAIL', 'WORK',    'Ola.Nordmann@Example.NO',               true,  '2022-12-13 08:00:00'),
  ('Ola.Nordmann@Example.NO',               'PHONE', 'MOBILE',  '+47 912 34 567',                        true,  null),
  ('kai_lee+invoices.2025@mailbox.example', 'EMAIL', 'BILLING', 'kai_lee+invoices.2025@mailbox.example', true,  '2025-02-03 09:00:00'),
  ('kai_lee+invoices.2025@mailbox.example', 'PHONE', 'WORK',    '+61 2 9374 4000',                       true,  '2025-02-03 09:10:00'),
  ('alexandra.petrova@example.bg',          'EMAIL', 'WORK',    'a.petrova@northwind-traders.example',   true,  '2023-09-10 10:00:00'),
  ('alexandra.petrova@example.bg',          'PHONE', 'WORK',    '(415) 555-0123',                        false, null),
  ('soren.lindqvist@example.se',            'PHONE', 'HOME',    '+44 161 496 0123',                      false, null),
  ('wei.li@example.cn',                     'PHONE', 'MOBILE',  '+86 138 0013 8000',                     true,  '2025-07-06 03:00:00'),
  ('marie-claire.dubois@example.fr',        'EMAIL', 'HOME',    'mc.dubois@example.fr',                  false, null),
  ('dante.russo@example.it',                'EMAIL', 'WORK',    'ordini@dantes-pizzeria.example',        true,  '2025-10-11 08:00:00')
) AS v (customer_email, kind, label, value, preferred, verified_at)
JOIN inventory.customers c ON c.email = v.customer_email
ON CONFLICT (customer_id, kind, value) DO NOTHING;
