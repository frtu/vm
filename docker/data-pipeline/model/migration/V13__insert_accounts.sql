-- Basic accounts, one per basic customer (owner found by email). Inserted only when the
-- account_ref is missing. credit_limit_minor is in cents of credit_currency (null = base_currency).
INSERT INTO inventory.accounts
  (account_ref, owner_customer_id, legal_name, display_name, aliases, country_code, base_currency,
   credit_currency, credit_limit_minor, payment_terms_days, status, notes, opened_at)
SELECT v.account_ref, c.id, v.legal_name, v.display_name, v.aliases::text[], v.country_code, v.base_currency,
       v.credit_currency, v.credit_limit_minor, v.payment_terms_days, v.status, v.notes, v.opened_at::timestamp
FROM (VALUES
  ('acct_OAK001', 'brandon.thomas@example.com', 'Oakwood Home Supplies LLC', 'Oakwood Home', null, 'US', 'USD',
   null, 1000000, 30, 'ACTIVE', 'Monthly invoice, paid by bank transfer', '2023-03-01 09:00:00'),
  ('acct_DAV001', 'sarah.davies@example.com', 'Davies Design Studio', null, null, 'US', 'USD',
   null, 0, 15, 'PENDING', null, '2023-03-02 09:00:00')
) AS v (account_ref, owner_email, legal_name, display_name, aliases, country_code, base_currency,
        credit_currency, credit_limit_minor, payment_terms_days, status, notes, opened_at)
JOIN inventory.customers c ON c.email = v.owner_email
ON CONFLICT (account_ref) DO NOTHING;
