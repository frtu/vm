-- Basic contacts: the phone numbers of the original seed (former `phone_numbers`) plus the primary email of each
-- basic customer. A contact points to its customer by email (no hard-coded id) and is inserted
-- only when missing (customer + kind + value).
INSERT INTO inventory.contacts (customer_id, kind, label, value, preferred, verified_at)
SELECT c.id, v.kind, v.label, v.value, v.preferred, v.verified_at::timestamp
FROM (VALUES
  ('brandon.thomas@example.com', 'EMAIL', 'WORK',   'brandon.thomas@example.com', true,  '2023-02-18 09:00:00'),
  ('brandon.thomas@example.com', 'PHONE', 'WORK',   '(800) 555‑2100',             true,  '2023-02-18 09:05:00'),
  ('sarah.davies@example.com',   'EMAIL', 'WORK',   'sarah.davies@example.com',   true,  '2023-02-18 10:00:00'),
  ('sarah.davies@example.com',   'PHONE', 'MOBILE', '(800) 555‑2100',             true,  null),
  ('sarah.davies@example.com',   'PHONE', 'HOME',   '(800) 555‑2200',             false, null),
  ('sarah.davies@example.com',   'PHONE', 'WORK',   '(800) 555‑2300',             false, null)
) AS v (customer_email, kind, label, value, preferred, verified_at)
JOIN inventory.customers c ON c.email = v.customer_email
ON CONFLICT (customer_id, kind, value) DO NOTHING;
