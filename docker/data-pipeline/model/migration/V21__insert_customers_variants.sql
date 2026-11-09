-- Customers whose values exercise every search behavior of the customer entity (see V1 and
-- ../tests/test_customers_search.py). A row is inserted only when its email is missing.
--
--  Behavior                 Stored                                   Finds                    Does not find
--  hyphenated given name    Marie-Claire Dubois                      claire dubois, MARIE-CLAIRE  marieclaire
--  hyphenated surname       Lars Berg-Hansen                         hansen lars              berghansen
--  accents                  Zoë Müller, Siobhán D'Arcy, Søren        zoe muller, siobhan, soren   zoemuller, mueller (name)
--  apostrophe               Siobhán D'Arcy                           arcy, D'ARCY             darcy (name; the email has it)
--  prefix (>= 3)            Alexandra Petrova                        alex, alex petr          al, Sasha (no nickname)
--  typo (1 edit, opt-in)    Tomasz Kowalski, Chidi Okafor            Kowalsky, Okafr, Okaofr  Kovalsky (2 edits), Okxxxx
--  short word (no typo)     Wei Li                                   li                       lu
--  email fragments          Ola.Nordmann@Example.NO                  ola.nordmann, OLA NORDMANN   olanordmann
--  email +tag               kai_lee+invoices.2025@mailbox.example    invoices 2025, mailbox   kailee, kai_lee@mailbox.example
--  identifier               cus_tko2304                              cus_tko2304              cus_tko2305, CUS_TKO2304, cus_tko
--  date + time zone         Chidi 2025-05-07 23:30 UTC, Wei 2025-07-05   05/07/2025 is ambiguous: one of them, after clarification
--  fixed list               status 0..3, country_code                SUSPENDED, NO            (resolved before the search)
INSERT INTO inventory.customers (customer_ref, first_name, last_name, email, street, zip, city, country_code, phone, status, registered_at)
VALUES
  ('cus_mcd2403', 'Marie-Claire', 'Dubois', 'marie-claire.dubois@example.fr', '8 Rue Mercière', '69002', 'Lyon', 'FR', '+33 4 78 37 00 00', 1, '2024-03-18 09:30:00'),
  ('cus_lbh2406', 'Lars', 'Berg-Hansen', 'lars.berg-hansen@example.no', 'Karl Johans gate 22', '0159', 'Oslo', 'NO', '+47 22 33 44 55', 1, '2024-06-01 08:00:00'),
  ('cus_zmu2501', 'Zoë', 'Müller', 'zoe.mueller@example.de', 'Torstraße 109', '10119', 'Berlin', 'DE', '+49 30 1234 5678', 0, '2025-01-14 10:00:00'),
  ('cus_sda2411', 'Siobhán', 'D''Arcy', 'siobhan.darcy@example.ie', '14 Grafton Street', 'D02 VF65', 'Dublin', 'IE', '+353 1 555 0142', 1, '2024-11-02 15:20:00'),
  ('cus_ape2309', 'Alexandra', 'Petrova', 'alexandra.petrova@example.bg', '25 Vitosha Blvd', '1000', 'Sofia', 'BG', '+359 2 555 0175', 1, '2023-09-09 12:00:00'),
  ('cus_tko2304', 'Tomasz', 'Kowalski', 'tomasz.kowalski@example.pl', 'ul. Marszałkowska 84', '00-514', 'Warsaw', 'PL', '+48 22 555 0190', 2, '2023-04-21 07:45:00'),
  ('cus_cok2505', 'Chidi', 'Okafor', 'chidi.okafor@example.ng', '12 Admiralty Way', '106104', 'Lagos', 'NG', '+234 1 555 0188', 1, '2025-05-07 23:30:00'),
  ('cus_wli2507', 'Wei', 'Li', 'wei.li@example.cn', '100 Century Avenue', '200120', 'Shanghai', 'CN', '+86 21 5555 0100', 1, '2025-07-05 11:00:00'),
  ('cus_ono2212', 'Ola', 'Nordmann', 'Ola.Nordmann@Example.NO', 'Bryggen 15', '5003', 'Bergen', 'NO', '+47 55 55 01 10', 3, '2022-12-12 12:12:00'),
  ('cus_kle2502', 'Kai', 'Lee', 'kai_lee+invoices.2025@mailbox.example', '1 Martin Place', '2000', 'Sydney', 'AU', '+61 2 9374 4000', 1, '2025-02-02 02:02:00'),
  ('cus_sli2408', 'Søren', 'Lindqvist', 'soren.lindqvist@example.se', 'Drottninggatan 53', '111 21', 'Stockholm', 'SE', '+46 8 555 0133', 1, '2024-08-08 08:08:00'),
  ('cus_dru2510', 'Dante', 'Russo', 'dante.russo@example.it', 'Via Toledo 256', '80132', 'Naples', 'IT', '+39 081 555 0166', 0, '2025-10-10 10:10:00')
ON CONFLICT (email) DO NOTHING;
