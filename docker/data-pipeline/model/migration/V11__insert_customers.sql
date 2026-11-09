-- Basic customers (the original inventory seed). A row is inserted only when its email is
-- missing. Phone values use a non-breaking hyphen (U+2011), as typed by the original seed:
-- the phone lookup compares digits only, so 800 555 2100 still finds them.
INSERT INTO inventory.customers (customer_ref, first_name, last_name, email, street, zip, city, country_code, phone, status, registered_at)
VALUES
  ('cus_bth2302', 'Brandon', 'Thomas', 'brandon.thomas@example.com', '29 Oakwood Drive', '90210', 'Los Angeles', 'US', '(800) 555‑2100', 1, '2023-02-17 21:36:42'),
  ('cus_sda2302', 'Sarah', 'Davies', 'sarah.davies@example.com', '29 Oakwood Drive', '90210', 'Los Angeles', 'US', null, 1, '2023-02-17 21:36:42')
ON CONFLICT (email) DO NOTHING;
