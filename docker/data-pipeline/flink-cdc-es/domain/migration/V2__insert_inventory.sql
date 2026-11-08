-- Seed data of ../../../db/init/10-create_inventory.sql. A row is inserted only when missing
-- (customers by email, phone numbers by customer + value). A phone number points to its
-- customer by email instead of a hard-coded id. Phone values use a non-breaking hyphen (U+2011).
-- Each inserted customer goes through CDC: Postgres -> Debezium -> Kafka -> ES `customers_connect`.
INSERT INTO inventory.customers (fname, lname, email, street, zip, city, phone, status, registered)
VALUES ('Brandon', 'Thomas', 'brandon.thomas@example.com', '29 Oakwood Drive', '90210', 'Los Angeles', '(800) 555‑2100', 1, '2023-02-17 21:36:42')
ON CONFLICT (email) DO NOTHING;

INSERT INTO inventory.customers (fname, lname, email, street, zip, city, phone, status, registered)
VALUES ('Sarah', 'Davies', 'sarah.davies@example.com', '29 Oakwood Drive', '90210', 'Los Angeles', null, 1, '2023-02-17 21:36:42')
ON CONFLICT (email) DO NOTHING;

INSERT INTO inventory.phone_numbers (customer_id, preferred, value)
SELECT c.id, p.preferred, p.value
FROM inventory.customers c
CROSS JOIN (VALUES (true, '(800) 555‑2100'), (false, '(800) 555‑2200'), (false, '(800) 555‑2300')) AS p (preferred, value)
WHERE c.email = 'sarah.davies@example.com'
  AND NOT EXISTS (
    SELECT 1 FROM inventory.phone_numbers n WHERE n.customer_id = c.id AND n.value = p.value
  );
