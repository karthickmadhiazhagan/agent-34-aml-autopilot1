# =============================================================================
# AML Autopilot – Seed Data
# 35 customers · 55 accounts · 300+ transactions
# Mix of AML typologies and clean/normal customer profiles
# Based on FinCEN SAR typologies and FATF guidance
# =============================================================================

puts "Clearing existing data..."
Alert.destroy_all
FinancialTransaction.destroy_all
Account.destroy_all
Customer.destroy_all

# =============================================================================
# HELPER LAMBDAS
# =============================================================================

# Quick wire transaction builder
wire = ->(ref, from, to, amt, date, desc, party = nil, country = nil) {
  FinancialTransaction.create!(
    txn_ref: ref, from_account: from, to_account: to,
    amount: amt, currency: "USD", txn_type: "wire_transfer",
    description: desc, counterparty_name: party, counterparty_country: country,
    location: (from || to)&.branch || "US",
    status: "completed", transacted_at: date
  )
}

# Quick cash deposit builder
deposit = ->(ref, acct, amt, date, desc, location = nil) {
  FinancialTransaction.create!(
    txn_ref: ref, to_account: acct,
    amount: amt, currency: "USD", txn_type: "cash_deposit",
    description: desc, counterparty_name: "Cash – Branch Teller",
    location: location || acct.branch,
    status: "completed", transacted_at: date
  )
}

# Quick ACH / direct deposit builder
ach = ->(ref, from, to, amt, date, desc, party = nil) {
  FinancialTransaction.create!(
    txn_ref: ref, from_account: from, to_account: to,
    amount: amt, currency: "USD", txn_type: "ach_transfer",
    description: desc, counterparty_name: party,
    location: (from || to)&.branch || "US",
    status: "completed", transacted_at: date
  )
}

# Relative date helper – keeps seed data in recent detection windows
def days_ago(n, hour: 10, min: 0)
  n == 0 ? Time.current.change(hour: hour, min: min)
         : n.days.ago.change(hour: hour, min: min)
end

puts "Seeding customers..."

# =============================================================================
# ── AML CUSTOMERS (will trigger detection rules) ──────────────────────────────
# =============================================================================

# --- Existing AML cast ---
carlos    = Customer.create!(customer_id: "CUST_001", name: "Carlos Mendez",
              email: "cmendez@email.com",               phone: "+1-305-555-0101",
              nationality: "MX", country_of_residence: "US",
              occupation: "Import/Export Consultant",   date_of_birth: "1975-03-15",
              risk_score: 78, kyc_status: "verified",   is_pep: false)

emmanuel  = Customer.create!(customer_id: "CUST_002", name: "Emmanuel Okafor",
              email: "e.okafor@govoffice.ng",            phone: "+1-202-555-0102",
              nationality: "NG", country_of_residence: "US",
              occupation: "Government Minister (retired)", date_of_birth: "1968-11-20",
              risk_score: 92, kyc_status: "enhanced_due_diligence", is_pep: true)

bright    = Customer.create!(customer_id: "CUST_003", name: "Bright Future LLC",
              email: "admin@brightfuturellc.com",        phone: "+1-212-555-0103",
              nationality: "US", country_of_residence: "US",
              occupation: "Investment Holding Company",  date_of_birth: nil,
              risk_score: 85, kyc_status: "verified",    is_pep: false)

sarah     = Customer.create!(customer_id: "CUST_004", name: "Sarah Chen",
              email: "schen@yahoo.com",                  phone: "+1-718-555-0104",
              nationality: "US", country_of_residence: "US",
              occupation: "Retired Teacher",             date_of_birth: "1945-07-08",
              risk_score: 40, kyc_status: "verified",    is_pep: false)

golden    = Customer.create!(customer_id: "CUST_005", name: "Golden Dragon Restaurant Group",
              email: "finance@goldendragon.biz",         phone: "+1-415-555-0105",
              nationality: "US", country_of_residence: "US",
              occupation: "Restaurant / Food Service",   date_of_birth: nil,
              risk_score: 62, kyc_status: "verified",    is_pep: false)

marcus    = Customer.create!(customer_id: "CUST_006", name: "Marcus Williams",
              email: "mwilliams@fastmail.com",           phone: "+1-404-555-0106",
              nationality: "US", country_of_residence: "US",
              occupation: "Freelance Contractor",        date_of_birth: "1990-05-22",
              risk_score: 71, kyc_status: "verified",    is_pep: false)

apex      = Customer.create!(customer_id: "CUST_007", name: "Apex Capital Partners LLC",
              email: "transactions@apexcapital.com",     phone: "+1-646-555-0107",
              nationality: "US", country_of_residence: "US",
              occupation: "Private Equity / Investment", date_of_birth: nil,
              risk_score: 68, kyc_status: "verified",    is_pep: false)

dimitri   = Customer.create!(customer_id: "CUST_008", name: "Dimitri Volkov",
              email: "dvolkov@protonmail.com",           phone: "+1-917-555-0108",
              nationality: "RU", country_of_residence: "US",
              occupation: "Cryptocurrency Trader",       date_of_birth: "1985-04-17",
              risk_score: 88, kyc_status: "enhanced_due_diligence", is_pep: false)

silk      = Customer.create!(customer_id: "CUST_009", name: "Silk Road Trading Co.",
              email: "ops@silkroadtrading.net",          phone: "+1-213-555-0109",
              nationality: "CN", country_of_residence: "US",
              occupation: "Import / Export Trading",     date_of_birth: nil,
              risk_score: 80, kyc_status: "enhanced_due_diligence", is_pep: false)

hassan    = Customer.create!(customer_id: "CUST_010", name: "Hassan Al-Rashid",
              email: "h.alrashid@businessemail.ae",      phone: "+1-310-555-0110",
              nationality: "AE", country_of_residence: "US",
              occupation: "Real Estate Developer",       date_of_birth: "1972-01-25",
              risk_score: 73, kyc_status: "verified",    is_pep: false)

diego     = Customer.create!(customer_id: "CUST_011", name: "Diego Ramirez",
              email: "dramirez@gmail.com",               phone: "+1-786-555-0111",
              nationality: "CO", country_of_residence: "US",
              occupation: "Day Laborer",                 date_of_birth: "1995-02-10",
              risk_score: 55, kyc_status: "verified",    is_pep: false)

ana       = Customer.create!(customer_id: "CUST_012", name: "Ana Torres",
              email: "atorres@hotmail.com",              phone: "+1-786-555-0112",
              nationality: "CO", country_of_residence: "US",
              occupation: "Cleaning Services",           date_of_birth: "1993-08-30",
              risk_score: 52, kyc_status: "verified",    is_pep: false)

luis      = Customer.create!(customer_id: "CUST_013", name: "Luis Vargas",
              email: "lvargas@email.com",                phone: "+1-786-555-0113",
              nationality: "MX", country_of_residence: "US",
              occupation: "Construction Worker",         date_of_birth: "1991-12-05",
              risk_score: 50, kyc_status: "verified",    is_pep: false)

victor    = Customer.create!(customer_id: "CUST_014", name: "Victor Salinas",
              email: "vsalinas@mailbox.com",             phone: "+1-786-555-0114",
              nationality: "CO", country_of_residence: "US",
              occupation: "Used Car Dealer",             date_of_birth: "1982-06-18",
              risk_score: 76, kyc_status: "verified",    is_pep: false)

# --- New AML customers ---

# HIGH_FREQUENCY + LARGE_AMOUNT: shell company cycling funds rapidly
rapid_cash = Customer.create!(customer_id: "CUST_015", name: "Rapid Cash Exchange LLC",
               email: "ops@rapidcashexchange.io",        phone: "+1-305-555-0115",
               nationality: "US", country_of_residence: "US",
               occupation: "Money Services Business",    date_of_birth: nil,
               risk_score: 82, kyc_status: "verified",   is_pep: false)

# UNUSUAL_GEOGRAPHY: transactions with IR, KP, SY
omar      = Customer.create!(customer_id: "CUST_016", name: "Omar Trade International LLC",
               email: "omar@omartrade.biz",              phone: "+1-213-555-0116",
               nationality: "AE", country_of_residence: "US",
               occupation: "International Commodities",  date_of_birth: nil,
               risk_score: 87, kyc_status: "enhanced_due_diligence", is_pep: false)

# UNUSUAL_GEOGRAPHY + LARGE_AMOUNT: Russian high-net-worth, post-sanctions evasion
pavel     = Customer.create!(customer_id: "CUST_017", name: "Pavel Ivanov",
               email: "p.ivanov@secure-mail.ru",         phone: "+1-212-555-0117",
               nationality: "RU", country_of_residence: "US",
               occupation: "Energy Sector Executive",    date_of_birth: "1971-09-03",
               risk_score: 91, kyc_status: "enhanced_due_diligence", is_pep: true)

# LARGE_AMOUNT + UNUSUAL_GEOGRAPHY: crypto-fiat with offshore layering
anastasia = Customer.create!(customer_id: "CUST_018", name: "Anastasia Petrov",
               email: "apetrov@cryptovault.net",         phone: "+1-415-555-0118",
               nationality: "RU", country_of_residence: "US",
               occupation: "Digital Assets Consultant",  date_of_birth: "1989-06-14",
               risk_score: 84, kyc_status: "enhanced_due_diligence", is_pep: false)

# DORMANT_ACTIVITY: dormant LLC reactivated after 4 years
legacy    = Customer.create!(customer_id: "CUST_019", name: "Legacy Industries LLC",
               email: "admin@legacyindustries.biz",      phone: "+1-312-555-0119",
               nationality: "US", country_of_residence: "US",
               occupation: "Inactive Holding Company",   date_of_birth: nil,
               risk_score: 67, kyc_status: "verified",   is_pep: false)

# LARGE_AMOUNT: structuring via multiple nominees
roberto   = Customer.create!(customer_id: "CUST_020", name: "Roberto Villa",
               email: "rvilla@privatemail.com",          phone: "+1-786-555-0120",
               nationality: "VE", country_of_residence: "US",
               occupation: "Property Developer",         date_of_birth: "1979-04-22",
               risk_score: 79, kyc_status: "verified",   is_pep: false)

# =============================================================================
# ── CLEAN CUSTOMERS (normal activity, should NOT trigger alerts) ───────────────
# =============================================================================

alice     = Customer.create!(customer_id: "CUST_021", name: "Alice Johnson",
               email: "alice.johnson@school.edu",        phone: "+1-617-555-0121",
               nationality: "US", country_of_residence: "US",
               occupation: "High School Teacher",        date_of_birth: "1982-04-10",
               risk_score: 8,  kyc_status: "verified",   is_pep: false)

bob       = Customer.create!(customer_id: "CUST_022", name: "Bob Smith",
               email: "bob.smith@accounting.com",        phone: "+1-312-555-0122",
               nationality: "US", country_of_residence: "US",
               occupation: "Staff Accountant",           date_of_birth: "1978-11-15",
               risk_score: 5,  kyc_status: "verified",   is_pep: false)

carol     = Customer.create!(customer_id: "CUST_023", name: "Carol White",
               email: "carol.white@hospital.org",        phone: "+1-617-555-0123",
               nationality: "US", country_of_residence: "US",
               occupation: "Registered Nurse",           date_of_birth: "1985-07-22",
               risk_score: 4,  kyc_status: "verified",   is_pep: false)

david     = Customer.create!(customer_id: "CUST_024", name: "David Brown",
               email: "dbrown@techcorp.com",             phone: "+1-408-555-0124",
               nationality: "US", country_of_residence: "US",
               occupation: "Software Engineer",          date_of_birth: "1991-02-28",
               risk_score: 6,  kyc_status: "verified",   is_pep: false)

emma      = Customer.create!(customer_id: "CUST_025", name: "Emma Davis",
               email: "emma.davis@agency.com",           phone: "+1-213-555-0125",
               nationality: "US", country_of_residence: "US",
               occupation: "Marketing Manager",          date_of_birth: "1987-09-05",
               risk_score: 7,  kyc_status: "verified",   is_pep: false)

frank     = Customer.create!(customer_id: "CUST_026", name: "Dr. Frank Miller",
               email: "fmiller@medclinic.com",           phone: "+1-312-555-0126",
               nationality: "US", country_of_residence: "US",
               occupation: "Family Physician",           date_of_birth: "1973-03-17",
               risk_score: 10, kyc_status: "verified",   is_pep: false)

grace     = Customer.create!(customer_id: "CUST_027", name: "Grace Kim",
               email: "grace@gracekimsbakery.com",       phone: "+1-503-555-0127",
               nationality: "US", country_of_residence: "US",
               occupation: "Bakery Owner",               date_of_birth: "1980-01-30",
               risk_score: 12, kyc_status: "verified",   is_pep: false)

henry     = Customer.create!(customer_id: "CUST_028", name: "Henry Park",
               email: "hpark@plumbing.com",              phone: "+1-503-555-0128",
               nationality: "US", country_of_residence: "US",
               occupation: "Licensed Plumber",           date_of_birth: "1976-06-11",
               risk_score: 9,  kyc_status: "verified",   is_pep: false)

isabella  = Customer.create!(customer_id: "CUST_029", name: "Isabella Chen",
               email: "isabella.chen@corp.com",          phone: "+1-206-555-0129",
               nationality: "US", country_of_residence: "US",
               occupation: "HR Manager",                 date_of_birth: "1983-12-04",
               risk_score: 6,  kyc_status: "verified",   is_pep: false)

james     = Customer.create!(customer_id: "CUST_030", name: "James Wilson",
               email: "jwilson@retailco.com",            phone: "+1-602-555-0130",
               nationality: "US", country_of_residence: "US",
               occupation: "Retail Store Manager",       date_of_birth: "1979-08-19",
               risk_score: 8,  kyc_status: "verified",   is_pep: false)

karen     = Customer.create!(customer_id: "CUST_031", name: "Karen Moore",
               email: "kmoore@dentalcare.com",           phone: "+1-602-555-0131",
               nationality: "US", country_of_residence: "US",
               occupation: "Dentist",                    date_of_birth: "1975-05-25",
               risk_score: 11, kyc_status: "verified",   is_pep: false)

liam      = Customer.create!(customer_id: "CUST_032", name: "Liam Thompson",
               email: "lthompson@itconsult.com",         phone: "+1-512-555-0132",
               nationality: "US", country_of_residence: "US",
               occupation: "IT Consultant",              date_of_birth: "1988-10-07",
               risk_score: 7,  kyc_status: "verified",   is_pep: false)

maria_s   = Customer.create!(customer_id: "CUST_033", name: "Maria Santos",
               email: "mariasantos@gmail.com",           phone: "+1-305-555-0133",
               nationality: "US", country_of_residence: "US",
               occupation: "Restaurant Server",          date_of_birth: "1994-03-16",
               risk_score: 5,  kyc_status: "verified",   is_pep: false)

nathan    = Customer.create!(customer_id: "CUST_034", name: "Nathan Kim",
               email: "nkim@restaurant.com",             phone: "+1-503-555-0134",
               nationality: "US", country_of_residence: "US",
               occupation: "Line Chef",                  date_of_birth: "1992-07-20",
               risk_score: 4,  kyc_status: "verified",   is_pep: false)

olivia    = Customer.create!(customer_id: "CUST_035", name: "Olivia Brown",
               email: "olivia.brown@university.edu",     phone: "+1-617-555-0135",
               nationality: "US", country_of_residence: "US",
               occupation: "Graduate Student",           date_of_birth: "2000-01-12",
               risk_score: 3,  kyc_status: "verified",   is_pep: false)

puts "Seeding accounts... (55 total)"

# =============================================================================
# ACCOUNTS
# =============================================================================

# ── AML accounts ──────────────────────────────────────────────────────────────
acc_carlos    = Account.create!(customer: carlos,     account_number: "CHK-CM-001",  account_type: "checking",  balance: 12_450.00,  currency: "USD", status: "active",  branch: "Miami Downtown",    opened_at: "2019-04-10")
acc_carlos2   = Account.create!(customer: carlos,     account_number: "SAV-CM-001",  account_type: "savings",   balance:  3_200.00,  currency: "USD", status: "active",  branch: "Miami Downtown",    opened_at: "2022-01-15")
acc_emmanuel  = Account.create!(customer: emmanuel,   account_number: "CHK-EO-001",  account_type: "checking",  balance: 498_250.00, currency: "USD", status: "active",  branch: "Washington DC",     opened_at: "2020-01-15")
acc_bright    = Account.create!(customer: bright,     account_number: "BIZ-BFL-001", account_type: "business",  balance:  28_000.00, currency: "USD", status: "active",  branch: "New York Midtown",  opened_at: "2021-06-01")
acc_bright2   = Account.create!(customer: bright,     account_number: "BIZ-BFL-002", account_type: "business",  balance:       0.00, currency: "USD", status: "closed",  branch: "New York",          opened_at: "2021-06-01")
acc_sarah     = Account.create!(customer: sarah,      account_number: "SAV-SC-001",  account_type: "savings",   balance: 220_000.00, currency: "USD", status: "dormant", branch: "Brooklyn",          opened_at: "2008-03-22")
acc_golden    = Account.create!(customer: golden,     account_number: "BIZ-GDR-001", account_type: "business",  balance: 185_000.00, currency: "USD", status: "active",  branch: "San Francisco",     opened_at: "2016-09-05")
acc_marcus    = Account.create!(customer: marcus,     account_number: "CHK-MW-001",  account_type: "checking",  balance:   1_850.00, currency: "USD", status: "active",  branch: "Atlanta",           opened_at: "2018-11-30")
acc_marcus2   = Account.create!(customer: marcus,     account_number: "SAV-MW-001",  account_type: "savings",   balance:       0.00, currency: "USD", status: "active",  branch: "Atlanta",           opened_at: "2023-06-01")
acc_apex      = Account.create!(customer: apex,       account_number: "BIZ-ACP-001", account_type: "business",  balance: 750_000.00, currency: "USD", status: "active",  branch: "New York Wall St",  opened_at: "2017-02-14")
acc_apex2     = Account.create!(customer: apex,       account_number: "BIZ-ACP-002", account_type: "business",  balance:       0.00, currency: "USD", status: "active",  branch: "New York",          opened_at: "2022-01-10")
acc_dimitri   = Account.create!(customer: dimitri,    account_number: "CHK-DV-001",  account_type: "checking",  balance:  95_000.00, currency: "USD", status: "active",  branch: "New York",          opened_at: "2022-07-20")
acc_dimitri2  = Account.create!(customer: dimitri,    account_number: "SAV-DV-001",  account_type: "savings",   balance:       0.00, currency: "USD", status: "active",  branch: "New York",          opened_at: "2023-05-01")
acc_silk      = Account.create!(customer: silk,       account_number: "BIZ-SR-001",  account_type: "business",  balance: 340_000.00, currency: "USD", status: "active",  branch: "Los Angeles",       opened_at: "2020-03-18")
acc_silk2     = Account.create!(customer: silk,       account_number: "BIZ-SR-002",  account_type: "business",  balance:       0.00, currency: "USD", status: "active",  branch: "Los Angeles",       opened_at: "2023-07-01")
acc_hassan    = Account.create!(customer: hassan,     account_number: "CHK-HA-001",  account_type: "checking",  balance:  55_000.00, currency: "USD", status: "active",  branch: "Beverly Hills",     opened_at: "2021-10-01")
acc_hassan2   = Account.create!(customer: hassan,     account_number: "SAV-HA-001",  account_type: "savings",   balance:       0.00, currency: "USD", status: "active",  branch: "Beverly Hills",     opened_at: "2023-04-01")
acc_diego     = Account.create!(customer: diego,      account_number: "CHK-DR-001",  account_type: "checking",  balance:   2_450.00, currency: "USD", status: "active",  branch: "Miami",             opened_at: "2023-01-10")
acc_ana       = Account.create!(customer: ana,        account_number: "CHK-AT-001",  account_type: "checking",  balance:   1_980.00, currency: "USD", status: "active",  branch: "Miami",             opened_at: "2023-03-05")
acc_luis      = Account.create!(customer: luis,       account_number: "CHK-LV-001",  account_type: "checking",  balance:   2_210.00, currency: "USD", status: "active",  branch: "Miami",             opened_at: "2023-06-15")
acc_victor    = Account.create!(customer: victor,     account_number: "CHK-VS-001",  account_type: "checking",  balance:  82_000.00, currency: "USD", status: "active",  branch: "Miami",             opened_at: "2021-05-20")
acc_rapid     = Account.create!(customer: rapid_cash, account_number: "BIZ-RC-001",  account_type: "business",  balance: 120_000.00, currency: "USD", status: "active",  branch: "Miami",             opened_at: "2023-09-01")
acc_omar      = Account.create!(customer: omar,       account_number: "BIZ-OT-001",  account_type: "business",  balance:  45_000.00, currency: "USD", status: "active",  branch: "Los Angeles",       opened_at: "2022-04-15")
acc_pavel     = Account.create!(customer: pavel,      account_number: "CHK-PI-001",  account_type: "checking",  balance: 380_000.00, currency: "USD", status: "active",  branch: "New York",          opened_at: "2021-11-20")
acc_anastasia = Account.create!(customer: anastasia,  account_number: "CHK-AP-001",  account_type: "checking",  balance:  62_000.00, currency: "USD", status: "active",  branch: "San Francisco",     opened_at: "2023-02-10")
acc_legacy    = Account.create!(customer: legacy,     account_number: "BIZ-LI-001",  account_type: "business",  balance:       0.00, currency: "USD", status: "dormant", branch: "Chicago",           opened_at: "2015-05-01")
acc_roberto   = Account.create!(customer: roberto,    account_number: "CHK-RV-001",  account_type: "checking",  balance:  18_000.00, currency: "USD", status: "active",  branch: "Miami",             opened_at: "2021-08-12")
acc_roberto2  = Account.create!(customer: roberto,    account_number: "SAV-RV-001",  account_type: "savings",   balance:   5_000.00, currency: "USD", status: "active",  branch: "Miami",             opened_at: "2022-03-01")

# ── Clean accounts ────────────────────────────────────────────────────────────
acc_alice     = Account.create!(customer: alice,      account_number: "CHK-AJ-001",  account_type: "checking",  balance:   4_200.00, currency: "USD", status: "active",  branch: "Boston",            opened_at: "2010-09-01")
acc_alice2    = Account.create!(customer: alice,      account_number: "SAV-AJ-001",  account_type: "savings",   balance:  22_000.00, currency: "USD", status: "active",  branch: "Boston",            opened_at: "2012-01-15")
acc_bob       = Account.create!(customer: bob,        account_number: "CHK-BS-001",  account_type: "checking",  balance:   7_800.00, currency: "USD", status: "active",  branch: "Chicago",           opened_at: "2009-05-20")
acc_carol     = Account.create!(customer: carol,      account_number: "CHK-CW-001",  account_type: "checking",  balance:   5_500.00, currency: "USD", status: "active",  branch: "Boston",            opened_at: "2015-03-10")
acc_david     = Account.create!(customer: david,      account_number: "CHK-DB-001",  account_type: "checking",  balance:  12_300.00, currency: "USD", status: "active",  branch: "San Jose",          opened_at: "2018-07-22")
acc_david2    = Account.create!(customer: david,      account_number: "SAV-DB-001",  account_type: "savings",   balance:  45_000.00, currency: "USD", status: "active",  branch: "San Jose",          opened_at: "2020-01-10")
acc_emma      = Account.create!(customer: emma,       account_number: "CHK-ED-001",  account_type: "checking",  balance:   6_100.00, currency: "USD", status: "active",  branch: "Los Angeles",       opened_at: "2016-11-05")
acc_frank     = Account.create!(customer: frank,      account_number: "CHK-FM-001",  account_type: "checking",  balance:  18_400.00, currency: "USD", status: "active",  branch: "Chicago",           opened_at: "2008-04-17")
acc_frank2    = Account.create!(customer: frank,      account_number: "SAV-FM-001",  account_type: "savings",   balance:  95_000.00, currency: "USD", status: "active",  branch: "Chicago",           opened_at: "2010-06-01")
acc_grace     = Account.create!(customer: grace,      account_number: "BIZ-GK-001",  account_type: "business",  balance:  14_000.00, currency: "USD", status: "active",  branch: "Portland",          opened_at: "2017-02-28")
acc_henry     = Account.create!(customer: henry,      account_number: "CHK-HP-001",  account_type: "checking",  balance:   8_900.00, currency: "USD", status: "active",  branch: "Portland",          opened_at: "2013-08-15")
acc_isabella  = Account.create!(customer: isabella,   account_number: "CHK-IC-001",  account_type: "checking",  balance:   9_600.00, currency: "USD", status: "active",  branch: "Seattle",           opened_at: "2014-10-01")
acc_james     = Account.create!(customer: james,      account_number: "CHK-JW-001",  account_type: "checking",  balance:   5_200.00, currency: "USD", status: "active",  branch: "Phoenix",           opened_at: "2011-07-04")
acc_karen     = Account.create!(customer: karen,      account_number: "CHK-KM-001",  account_type: "checking",  balance:  16_700.00, currency: "USD", status: "active",  branch: "Phoenix",           opened_at: "2007-03-22")
acc_liam      = Account.create!(customer: liam,       account_number: "CHK-LT-001",  account_type: "checking",  balance:  11_200.00, currency: "USD", status: "active",  branch: "Austin",            opened_at: "2019-09-15")
acc_maria_s   = Account.create!(customer: maria_s,    account_number: "CHK-MS-001",  account_type: "checking",  balance:   1_800.00, currency: "USD", status: "active",  branch: "Miami",             opened_at: "2021-05-10")
acc_nathan    = Account.create!(customer: nathan,     account_number: "CHK-NK-001",  account_type: "checking",  balance:   3_100.00, currency: "USD", status: "active",  branch: "Portland",          opened_at: "2020-08-01")
acc_olivia    = Account.create!(customer: olivia,     account_number: "CHK-OB-001",  account_type: "checking",  balance:   1_200.00, currency: "USD", status: "active",  branch: "Boston",            opened_at: "2022-09-01")

puts "Seeding transactions..."

# =============================================================================
# AML TRANSACTIONS
# =============================================================================

# ---------------------------------------------------------------------------
# SCENARIO 1: STRUCTURING / SMURFING – Carlos Mendez
# Multiple cash deposits just below the $10,000 CTR threshold over 14 days
# ---------------------------------------------------------------------------
deposit.("TXN-CM-001", acc_carlos,  9_800.00, 25.days.ago, "Cash deposit – personal savings")
deposit.("TXN-CM-002", acc_carlos,  9_750.00, 22.days.ago, "Cash deposit")
deposit.("TXN-CM-003", acc_carlos,  9_500.00, 19.days.ago, "Cash deposit – consulting fee")
deposit.("TXN-CM-004", acc_carlos,  9_900.00, 16.days.ago, "Cash deposit")
deposit.("TXN-CM-005", acc_carlos,  9_600.00, 12.days.ago, "Cash deposit – misc income")
# Outbound wire after collection
wire.("TXN-CM-006", acc_carlos, nil, 48_000.00, 11.days.ago,
      "Wire – property acquisition deposit", "Panama Realty Partners S.A.", "PA")

# ---------------------------------------------------------------------------
# SCENARIO 2: RAPID PASS-THROUGH / LAYERING – Bright Future LLC
# $500K offshore wire in; $455K distributed to 5 accounts within 48 hours
# ---------------------------------------------------------------------------
wire.("TXN-BF-001", nil, acc_bright, 500_000.00, 20.days.ago,
      "Incoming international wire – investment capital", "Cayman Holdings Ltd.", "KY")
wire.("TXN-BF-002", acc_bright, acc_apex,    90_000.00, 20.days.ago.change(hour: 14), "Transfer – project funding")
wire.("TXN-BF-003", acc_bright, acc_hassan,  85_000.00, 20.days.ago.change(hour: 16), "Transfer – consulting retainer")
wire.("TXN-BF-004", acc_bright, acc_dimitri,100_000.00, 19.days.ago.change(hour: 9),  "Transfer – investment tranche")
wire.("TXN-BF-005", acc_bright, acc_marcus,  95_000.00, 19.days.ago.change(hour: 11), "Transfer – service fees")
wire.("TXN-BF-006", acc_bright, acc_silk,    85_000.00, 19.days.ago.change(hour: 13), "Transfer – vendor payment")

# ---------------------------------------------------------------------------
# SCENARIO 3: PEP SUSPICIOUS WIRE – Emmanuel Okafor
# Retired government minister receives $450K from unknown offshore entity
# ---------------------------------------------------------------------------
wire.("TXN-EO-001", nil, acc_emmanuel, 450_000.00, 35.days.ago,
      "International wire – advisory compensation", "Meridian Global Advisors Ltd.", "CY")
wire.("TXN-EO-002", acc_emmanuel, nil, 200_000.00, 33.days.ago,
      "Transfer – real estate escrow", "DC Metro Realty Trust")
wire.("TXN-EO-003", acc_emmanuel, nil, 150_000.00, 30.days.ago,
      "Transfer – Okafor Family Trust account", "Okafor Family Trust", "CH")
FinancialTransaction.create!(
  txn_ref: "TXN-EO-004", from_account: acc_emmanuel, amount: 80_000.00, currency: "USD",
  txn_type: "cash_withdrawal", description: "Cash withdrawal", location: "Washington, DC",
  status: "completed", transacted_at: 27.days.ago
)

# ---------------------------------------------------------------------------
# SCENARIO 4: DORMANT ACCOUNT REACTIVATION – Sarah Chen
# Dormant savings account suddenly receives $220K wire from HK law firm
# ---------------------------------------------------------------------------
wire.("TXN-SC-001", nil, acc_sarah, 220_000.00, 40.days.ago,
      "Wire – estate settlement proceeds", "Pacific Rim Law Group", "HK")
wire.("TXN-SC-002", acc_sarah, nil, 100_000.00, 37.days.ago,
      "Transfer – investment account", "Unknown Brokerage – Account 9927")
FinancialTransaction.create!(
  txn_ref: "TXN-SC-003", from_account: acc_sarah, amount: 50_000.00, currency: "USD",
  txn_type: "cash_withdrawal", description: "Cash withdrawal", location: "Brooklyn, NY",
  status: "completed", transacted_at: 35.days.ago
)

# ---------------------------------------------------------------------------
# SCENARIO 5: CASH-INTENSIVE BUSINESS ABUSE – Golden Dragon Restaurant
# Weekly cash deposits 700% above historical baseline
# ---------------------------------------------------------------------------
[
  ["TXN-GD-001", 52.days.ago,  52_400.00],
  ["TXN-GD-002", 45.days.ago,  61_800.00],
  ["TXN-GD-003", 38.days.ago,  58_200.00],
  ["TXN-GD-004", 31.days.ago,  63_500.00],
  ["TXN-GD-005", 24.days.ago,  55_900.00],
  ["TXN-GD-006", 17.days.ago,  57_300.00],
].each { |ref, date, amt| deposit.(ref, acc_golden, amt, date, "Weekly restaurant cash revenue deposit") }

# ---------------------------------------------------------------------------
# SCENARIO 6: FUNNEL ACCOUNT – Marcus Williams
# 12 ACH inflows from unrelated parties; entire balance cleared via cash
# ---------------------------------------------------------------------------
[
  ["TXN-MW-001", 28.days.ago.change(hour: 9),  1_800.00, "Payment for services – Invoice #1042"],
  ["TXN-MW-002", 27.days.ago.change(hour: 11), 2_400.00, "Freelance project payment"],
  ["TXN-MW-003", 26.days.ago.change(hour: 14), 1_950.00, "Consulting fee"],
  ["TXN-MW-004", 25.days.ago.change(hour: 10), 2_200.00, "Project deliverable payment"],
  ["TXN-MW-005", 24.days.ago.change(hour: 16), 1_700.00, "Service payment – Nov batch"],
  ["TXN-MW-006", 23.days.ago.change(hour: 9),  2_500.00, "Freelance – web development"],
  ["TXN-MW-007", 22.days.ago.change(hour: 13), 1_850.00, "Payment ref: INV-2024-1107"],
  ["TXN-MW-008", 21.days.ago.change(hour: 11), 2_100.00, "Consulting retainer"],
  ["TXN-MW-009", 20.days.ago.change(hour: 14), 1_900.00, "Project completion bonus"],
  ["TXN-MW-010", 19.days.ago.change(hour: 10), 2_300.00, "Service fee – final payment"],
  ["TXN-MW-011", 18.days.ago.change(hour: 12), 1_750.00, "Freelance payment"],
  ["TXN-MW-012", 17.days.ago.change(hour: 15), 2_050.00, "Invoice settlement"],
].each { |ref, date, amt, desc| ach.(ref, nil, acc_marcus, amt, date, desc, "Various Payers") }
FinancialTransaction.create!(
  txn_ref: "TXN-MW-013", from_account: acc_marcus, amount: 24_500.00, currency: "USD",
  txn_type: "cash_withdrawal", description: "ATM – full balance cleared",
  location: "Atlanta, GA", status: "completed", transacted_at: 16.days.ago
)

# ---------------------------------------------------------------------------
# SCENARIO 7: SMURFING (COORDINATED DEPOSITS) – Diego, Ana, Luis → Victor
# Three low-income workers make same-day deposits to Victor Salinas's account
# ---------------------------------------------------------------------------
[
  ["TXN-SM-001", "Diego Ramirez (CUST_011)",  9_100.00, 14.days.ago.change(hour: 9)],
  ["TXN-SM-002", "Ana Torres (CUST_012)",      8_900.00, 14.days.ago.change(hour: 10)],
  ["TXN-SM-003", "Luis Vargas (CUST_013)",     9_400.00, 14.days.ago.change(hour: 11)],
  ["TXN-SM-004", "Diego Ramirez (CUST_011)",   8_800.00,  7.days.ago.change(hour: 9)],
  ["TXN-SM-005", "Ana Torres (CUST_012)",       9_200.00,  7.days.ago.change(hour: 10)],
  ["TXN-SM-006", "Luis Vargas (CUST_013)",      8_700.00,  7.days.ago.change(hour: 11)],
].each do |ref, sender, amt, date|
  FinancialTransaction.create!(
    txn_ref: ref, to_account: acc_victor, amount: amt, currency: "USD",
    txn_type: "ach_transfer", description: "Funds transfer", location: "Miami, FL",
    counterparty_name: sender, status: "completed", transacted_at: date
  )
end
wire.("TXN-SM-007", acc_victor, nil, 54_100.00, 6.days.ago,
      "Wire – vehicle purchase settlement", "Panama Auto Brokers S.A.", "PA")

# ---------------------------------------------------------------------------
# SCENARIO 8: ROUND-DOLLAR WIRES – Apex Capital Partners
# Exact $50,000 wires with no business justification, to BVI entities
# ---------------------------------------------------------------------------
[
  ["TXN-AP-001", 60.days.ago], ["TXN-AP-002", 57.days.ago],
  ["TXN-AP-003", 53.days.ago], ["TXN-AP-004", 50.days.ago],
  ["TXN-AP-005", 46.days.ago], ["TXN-AP-006", 43.days.ago],
  ["TXN-AP-007", 39.days.ago],
].each do |ref, date|
  wire.(ref, acc_apex, nil, 50_000.00, date, ref, "Various offshore recipients", "VG")
end

# ---------------------------------------------------------------------------
# SCENARIO 9: CRYPTO-TO-FIAT CONVERSION – Dimitri Volkov
# Large deposits from crypto exchanges then wired to RU entity
# ---------------------------------------------------------------------------
[
  ["TXN-DV-001", 75.days.ago, 45_000.00, "Coinbase Pro – USD withdrawal"],
  ["TXN-DV-002", 68.days.ago, 38_500.00, "Kraken exchange – fiat withdrawal"],
  ["TXN-DV-003", 61.days.ago, 52_000.00, "Binance US – BTC liquidation"],
  ["TXN-DV-004", 54.days.ago, 41_000.00, "Coinbase – ETH sell settlement"],
  ["TXN-DV-005", 47.days.ago, 48_500.00, "Crypto exchange withdrawal"],
].each do |ref, date, amt, desc|
  FinancialTransaction.create!(
    txn_ref: ref, to_account: acc_dimitri, amount: amt, currency: "USD",
    txn_type: "crypto_conversion", description: desc, location: "New York, NY",
    counterparty_name: desc.split("–").first.strip,
    status: "completed", transacted_at: date
  )
end
wire.("TXN-DV-006", acc_dimitri, nil, 120_000.00, 40.days.ago,
      "International wire – personal investment", "Baltic Crypto Holdings OÜ", "EE")
wire.("TXN-DV-007", acc_dimitri, nil,  80_000.00, 35.days.ago,
      "Transfer – offshore account", "Volkov Family Fund", "RU")

# ---------------------------------------------------------------------------
# SCENARIO 10: TRADE-BASED MONEY LAUNDERING – Silk Road Trading Co.
# Import company receives payments 10× declared invoice values from China
# ---------------------------------------------------------------------------
[
  ["TXN-SR-001", 90.days.ago,  280_000.00, "Invoice #SR-2024-071 – Electronics shipment", "Fujian Horizon Tech Ltd.", "CN"],
  ["TXN-SR-002", 76.days.ago,  195_000.00, "Invoice #SR-2024-072 – Consumer goods",        "Guangzhou Star Exports",  "CN"],
  ["TXN-SR-003", 62.days.ago,  320_000.00, "Invoice #SR-2024-073 – Machinery parts",       "Shanghai Pacific Trade",  "CN"],
  ["TXN-SR-004", 48.days.ago,  245_000.00, "Invoice #SR-2024-074 – Textiles",              "Beijing Allied Supply",   "CN"],
  ["TXN-SR-005", 34.days.ago,  310_000.00, "Invoice #SR-2024-075 – Electronics",           "Shenzhen Global Traders", "CN"],
].each { |ref, date, amt, desc, party, ctry| wire.(ref, nil, acc_silk, amt, date, desc, party, ctry) }
wire.("TXN-SR-006", acc_silk, nil, 1_100_000.00, 20.days.ago,
      "Bulk payment – supplier settlement Q3", "Sunrise Commodity Group Ltd.", "HK")

# ---------------------------------------------------------------------------
# SCENARIO 11: HIGH TRANSACTION FREQUENCY – Rapid Cash Exchange LLC
# 14 transactions within a 10-hour window (HIGH_FREQUENCY rule trigger)
# ---------------------------------------------------------------------------
[
  ["TXN-RC-001",  1, "08:00", 18_500.00, nil,    acc_rapid, "Wire in – client remittance batch 1",     "Overseas Payer A",     "MX"],
  ["TXN-RC-002",  1, "08:30", 12_000.00, nil,    acc_rapid, "Wire in – client remittance batch 2",     "Overseas Payer B",     "GT"],
  ["TXN-RC-003",  1, "09:00", 22_000.00, nil,    acc_rapid, "Wire in – client remittance batch 3",     "Overseas Payer C",     "HN"],
  ["TXN-RC-004",  1, "09:30",  8_500.00, nil,    acc_rapid, "ACH in – settlement",                     "Domestic Partner LLC"],
  ["TXN-RC-005",  1, "10:00", 15_000.00, nil,    acc_rapid, "Wire in – client remittance batch 4",     "Overseas Payer D",     "SV"],
  ["TXN-RC-006",  1, "10:30", 19_500.00, acc_rapid, nil,    "Wire out – disbursement to beneficiaries","Beneficiary Group A"],
  ["TXN-RC-007",  1, "11:00", 21_000.00, acc_rapid, nil,    "Wire out – disbursement",                 "Beneficiary Group B",  "MX"],
  ["TXN-RC-008",  1, "11:30",  9_000.00, nil,    acc_rapid, "ACH in – cash float top-up",              "Internal Source LLC"],
  ["TXN-RC-009",  1, "12:00", 17_500.00, acc_rapid, nil,    "Wire out – client payout",                "Beneficiary Group C",  "CO"],
  ["TXN-RC-010",  1, "12:30", 14_000.00, nil,    acc_rapid, "Wire in – client settlement",             "Overseas Payer E",     "PE"],
  ["TXN-RC-011",  1, "13:00", 11_500.00, acc_rapid, nil,    "Wire out – disbursement batch",           "Beneficiary Group D"],
  ["TXN-RC-012",  1, "13:30", 16_000.00, acc_rapid, nil,    "Wire out – client payout",                "Beneficiary Group E",  "BR"],
  ["TXN-RC-013",  1, "14:00", 23_000.00, nil,    acc_rapid, "Wire in – batch settlement",              "Overseas Payer F",     "EC"],
  ["TXN-RC-014",  1, "15:00", 13_500.00, acc_rapid, nil,    "Wire out – final disbursement",           "Beneficiary Group F",  "DO"],
].each do |ref, days_back, time_str, amt, from_acc, to_acc, desc, party, ctry|
  h, m = time_str.split(":").map(&:to_i)
  FinancialTransaction.create!(
    txn_ref: ref, from_account: from_acc, to_account: to_acc,
    amount: amt, currency: "USD", txn_type: "wire_transfer",
    description: desc, counterparty_name: party, counterparty_country: ctry,
    location: "Miami, FL", status: "completed",
    transacted_at: days_back.days.ago.change(hour: h, min: m)
  )
end

# ---------------------------------------------------------------------------
# SCENARIO 12: UNUSUAL GEOGRAPHY (HIGH-RISK COUNTRIES) – Omar Trade LLC
# Wires involving Iran (IR) and Syria (SY) — sanctioned jurisdictions
# ---------------------------------------------------------------------------
wire.("TXN-OT-001", nil, acc_omar, 180_000.00, 5.days.ago,
      "Wire – commodity procurement payment", "Tehran Commodities Exchange", "IR")
wire.("TXN-OT-002", nil, acc_omar,  95_000.00, 4.days.ago,
      "Wire – trade settlement", "Damascus Industrial Group", "SY")
wire.("TXN-OT-003", acc_omar, nil, 260_000.00, 3.days.ago,
      "Wire – supplier payment consolidated", "Dubai Clearing House Ltd.", "AE")
wire.("TXN-OT-004", nil, acc_omar,  75_000.00, 2.days.ago,
      "Wire – logistics advance payment", "Pyongyang Trade Bureau", "KP")

# ---------------------------------------------------------------------------
# SCENARIO 13: PEP + UNUSUAL GEOGRAPHY – Pavel Ivanov
# Russian PEP receives large wires and routes funds back to RU/KP entities
# ---------------------------------------------------------------------------
wire.("TXN-PI-001", nil, acc_pavel, 350_000.00, 10.days.ago,
      "Wire – business acquisition proceeds", "Cyprus Investment Bank Ltd.", "CY")
wire.("TXN-PI-002", nil, acc_pavel, 120_000.00,  8.days.ago,
      "Wire – consulting compensation", "Belize Advisors Ltd.", "BZ")
wire.("TXN-PI-003", acc_pavel, nil, 280_000.00,  6.days.ago,
      "Wire – investment portfolio transfer", "Moscow Capital Partners", "RU")
wire.("TXN-PI-004", acc_pavel, nil,  75_000.00,  5.days.ago,
      "Wire – family trust distribution", "North Star Finance (DPRK)", "KP")
wire.("TXN-PI-005", acc_pavel, nil, 100_000.00,  3.days.ago,
      "Wire – private equity transfer", "Minsk Holdings JLLC", "BY")

# ---------------------------------------------------------------------------
# SCENARIO 14: CRYPTO LAYERING – Anastasia Petrov
# Large crypto-to-fiat deposits, then multi-country outbound routing
# ---------------------------------------------------------------------------
[
  ["TXN-AP2-001", 15.days.ago, 75_000.00, "Tornado Cash mixer withdrawal – batch A"],
  ["TXN-AP2-002", 12.days.ago, 60_000.00, "Crypto exchange fiat withdrawal"],
  ["TXN-AP2-003",  9.days.ago, 88_000.00, "DeFi protocol settlement"],
].each do |ref, date, amt, desc|
  FinancialTransaction.create!(
    txn_ref: ref, to_account: acc_anastasia, amount: amt, currency: "USD",
    txn_type: "crypto_conversion", description: desc, location: "San Francisco, CA",
    counterparty_name: "Crypto Platform", status: "completed", transacted_at: date
  )
end
wire.("TXN-AP2-004", acc_anastasia, nil, 90_000.00, 7.days.ago,
      "Wire – investment transfer", "North Korea Finance Bureau", "KP")
wire.("TXN-AP2-005", acc_anastasia, nil, 50_000.00, 5.days.ago,
      "Wire – offshore account", "Tehran Capital Group", "IR")
wire.("TXN-AP2-006", acc_anastasia, nil, 40_000.00, 3.days.ago,
      "Wire – consulting fees", "Damascus Holdings", "SY")

# ---------------------------------------------------------------------------
# SCENARIO 15: DORMANT ACCOUNT REACTIVATION – Legacy Industries LLC
# Business account dormant 4+ years, suddenly wired $400K
# ---------------------------------------------------------------------------
wire.("TXN-LI-001", nil, acc_legacy, 400_000.00, 45.days.ago,
      "Wire – business restructuring capital", "Offshore Holdings Group", "KY")
wire.("TXN-LI-002", acc_legacy, nil, 180_000.00, 43.days.ago,
      "Wire – vendor settlement", "Shell Vendor Corp.", "BZ")
wire.("TXN-LI-003", acc_legacy, nil, 150_000.00, 41.days.ago,
      "Wire – management fee", "Chicago Advisory LLC")
wire.("TXN-LI-004", acc_legacy, nil,  60_000.00, 39.days.ago,
      "Wire – operational transfer", "Unknown Beneficiary Ltd.", "PA")

# ---------------------------------------------------------------------------
# SCENARIO 16: STRUCTURING (LARGE CUMULATIVE) – Roberto Villa
# Multiple outbound wires totaling $85K over 25 days — above cumulative threshold
# ---------------------------------------------------------------------------
wire.("TXN-RV-001", acc_roberto, nil, 14_500.00, 25.days.ago,
      "Wire – property deposit", "Miami Realty LLC")
wire.("TXN-RV-002", acc_roberto, nil, 13_800.00, 20.days.ago,
      "Wire – legal fees", "Offshore Law Associates", "PA")
wire.("TXN-RV-003", acc_roberto, nil, 12_900.00, 15.days.ago,
      "Wire – consultant payment", "Caracas Consulting S.A.", "VE")
wire.("TXN-RV-004", acc_roberto, nil, 11_500.00, 10.days.ago,
      "Wire – service fee", "unnamed beneficiary")
wire.("TXN-RV-005", acc_roberto, nil, 13_200.00,  5.days.ago,
      "Wire – final settlement", "Island Holdings Ltd.", "KY")
wire.("TXN-RV-006", acc_roberto, nil, 10_800.00,  2.days.ago,
      "Wire – misc transfer", "Unknown Corp", "BZ")

# =============================================================================
# CLEAN TRANSACTIONS
# =============================================================================

# ---------------------------------------------------------------------------
# CLEAN: Alice Johnson – Teacher
# Regular biweekly salary + modest living expenses
# ---------------------------------------------------------------------------
ach.("TXN-AJ-001", nil, acc_alice,  3_500.00, 28.days.ago, "Direct deposit – payroll SCHOOL DIST", "Boston School District")
ach.("TXN-AJ-002", nil, acc_alice,  3_500.00, 14.days.ago, "Direct deposit – payroll SCHOOL DIST", "Boston School District")
ach.("TXN-AJ-003", acc_alice, nil,    850.00, 25.days.ago, "Rent payment – automated", "Boston Properties Inc")
ach.("TXN-AJ-004", acc_alice, nil,    120.00, 23.days.ago, "Utility bill – auto pay",  "Eversource Energy")
ach.("TXN-AJ-005", acc_alice, nil,    200.00, 18.days.ago, "Savings transfer",         nil)
ach.("TXN-AJ-006", nil, acc_alice2,   200.00, 18.days.ago, "Savings transfer – self",  nil)
ach.("TXN-AJ-007", acc_alice, nil,     65.00, 12.days.ago, "Netflix / streaming",      "Netflix Inc")

# ---------------------------------------------------------------------------
# CLEAN: Bob Smith – Accountant
# Monthly salary, rent, utilities, gym
# ---------------------------------------------------------------------------
ach.("TXN-BS-001", nil, acc_bob,    5_200.00, 30.days.ago, "Payroll – Deloitte LLP",   "Deloitte LLP")
ach.("TXN-BS-002", acc_bob, nil,    1_400.00, 28.days.ago, "Rent – automated",         "Chicago Apt Management")
ach.("TXN-BS-003", acc_bob, nil,      150.00, 26.days.ago, "Utilities",                "ComEd Electric")
ach.("TXN-BS-004", acc_bob, nil,       50.00, 20.days.ago, "Gym membership",           "Planet Fitness")
ach.("TXN-BS-005", nil, acc_bob,    5_200.00,  1.day.ago,  "Payroll – Deloitte LLP",   "Deloitte LLP")

# ---------------------------------------------------------------------------
# CLEAN: Carol White – Nurse
# Biweekly hospital payroll, small recurring bills
# ---------------------------------------------------------------------------
ach.("TXN-CW-001", nil, acc_carol,  2_900.00, 27.days.ago, "Payroll – Mass General Hospital", "Mass General Hospital")
ach.("TXN-CW-002", acc_carol, nil,    900.00, 25.days.ago, "Rent payment",            "Boston Rentals LLC")
ach.("TXN-CW-003", acc_carol, nil,     95.00, 22.days.ago, "Cell phone – Verizon",    "Verizon Wireless")
ach.("TXN-CW-004", nil, acc_carol,  2_900.00, 13.days.ago, "Payroll – Mass General",  "Mass General Hospital")
ach.("TXN-CW-005", acc_carol, nil,    150.00,  8.days.ago, "Grocery auto-pay",        "Market Basket")

# ---------------------------------------------------------------------------
# CLEAN: David Brown – Software Engineer
# High salary, savings, small international wire to family (legitimate)
# ---------------------------------------------------------------------------
ach.("TXN-DB-001", nil, acc_david,  8_500.00, 30.days.ago, "Payroll – TechCorp Inc",  "TechCorp Inc")
ach.("TXN-DB-002", acc_david, nil,  2_000.00, 28.days.ago, "Rent – San Jose apt",     "Equity Residential")
ach.("TXN-DB-003", nil, acc_david2, 1_500.00, 27.days.ago, "Monthly savings",         nil)
ach.("TXN-DB-004", acc_david, nil,    180.00, 20.days.ago, "PG&E utility",            "PG&E")
wire.("TXN-DB-005", acc_david, nil,   800.00, 15.days.ago,
      "Monthly support to family – India", "David Brown (family)", "IN")
ach.("TXN-DB-006", nil, acc_david,  8_500.00,  1.day.ago,  "Payroll – TechCorp Inc",  "TechCorp Inc")

# ---------------------------------------------------------------------------
# CLEAN: Emma Davis – Marketing Manager
# Regular salary, credit card payments, small Amazon charges
# ---------------------------------------------------------------------------
ach.("TXN-ED-001", nil, acc_emma,  4_800.00, 29.days.ago, "Payroll – Creative Agency", "Creative Agency Inc")
ach.("TXN-ED-002", acc_emma, nil,  1_100.00, 27.days.ago, "Rent",                      "LA Properties LLC")
ach.("TXN-ED-003", acc_emma, nil,    300.00, 22.days.ago, "Credit card payment",       "Chase Visa")
ach.("TXN-ED-004", acc_emma, nil,     75.00, 18.days.ago, "Amazon Prime + charges",    "Amazon")
ach.("TXN-ED-005", nil, acc_emma,  4_800.00,  1.day.ago,  "Payroll – Creative Agency", "Creative Agency Inc")

# ---------------------------------------------------------------------------
# CLEAN: Frank Miller – Doctor
# High income, mortgage, savings, single legitimate international conference wire
# ---------------------------------------------------------------------------
ach.("TXN-FM-001", nil, acc_frank,  12_000.00, 30.days.ago, "Net pay – Medical Clinic", "Northshore Medical Clinic")
ach.("TXN-FM-002", acc_frank, nil,   2_800.00, 28.days.ago, "Mortgage payment",         "Wells Fargo Mortgage")
ach.("TXN-FM-003", nil, acc_frank2,  3_000.00, 27.days.ago, "Transfer to savings",      nil)
ach.("TXN-FM-004", acc_frank, nil,     250.00, 20.days.ago, "Medical malpractice ins.", "AMA Insurance")
wire.("TXN-FM-005", acc_frank, nil,  4_500.00, 10.days.ago,
      "Conference registration – AMA Vienna 2026", "AMA International", "AT")
ach.("TXN-FM-006", nil, acc_frank,  12_000.00,  1.day.ago,  "Net pay – Medical Clinic", "Northshore Medical Clinic")

# ---------------------------------------------------------------------------
# CLEAN: Grace Kim – Bakery Owner (legitimate cash-intensive business)
# Modest cash deposits consistent with small bakery turnover
# ---------------------------------------------------------------------------
deposit.("TXN-GK-001", acc_grace,  1_800.00, 27.days.ago, "Weekly cash sales – bakery")
deposit.("TXN-GK-002", acc_grace,  2_100.00, 20.days.ago, "Weekly cash sales – bakery")
deposit.("TXN-GK-003", acc_grace,  1_950.00, 13.days.ago, "Weekly cash sales – bakery")
deposit.("TXN-GK-004", acc_grace,  2_200.00,  6.days.ago, "Weekly cash sales – bakery")
ach.("TXN-GK-005",    acc_grace, nil, 1_200.00, 25.days.ago, "Supplier – flour & dairy", "Northwest Baking Supply")
ach.("TXN-GK-006",    acc_grace, nil,   800.00, 18.days.ago, "Rent – bakery premises",   "Portland Commercial RE")

# ---------------------------------------------------------------------------
# CLEAN: Henry Park – Plumber
# Irregular but modest cash + check income, typical small trade business
# ---------------------------------------------------------------------------
deposit.("TXN-HP-001", acc_henry, 2_500.00, 26.days.ago, "Job payment – residential repair")
deposit.("TXN-HP-002", acc_henry, 1_800.00, 19.days.ago, "Job payment – commercial client")
deposit.("TXN-HP-003", acc_henry, 3_100.00, 12.days.ago, "Job payment – emergency call-out")
ach.("TXN-HP-004", acc_henry, nil, 480.00, 24.days.ago, "Truck payment – auto loan", "Ford Credit")
ach.("TXN-HP-005", acc_henry, nil, 120.00, 17.days.ago, "Tools supply – Home Depot", "Home Depot")

# ---------------------------------------------------------------------------
# CLEAN: Isabella Chen – HR Manager
# Steady monthly salary, rent, modest international transfer to parents (CA)
# ---------------------------------------------------------------------------
ach.("TXN-IC-001", nil, acc_isabella,  5_500.00, 30.days.ago, "Payroll – Corp HQ",      "GlobalCorp Inc")
ach.("TXN-IC-002", acc_isabella, nil,  1_500.00, 28.days.ago, "Rent – Seattle apt",     "Seattle Realty Partners")
ach.("TXN-IC-003", acc_isabella, nil,    110.00, 22.days.ago, "Internet – Comcast",     "Comcast")
wire.("TXN-IC-004", acc_isabella, nil,  1_000.00, 15.days.ago,
      "Monthly support – parents", "Isabella Chen (parents)", "CA")
ach.("TXN-IC-005", nil, acc_isabella,  5_500.00,  1.day.ago,  "Payroll – Corp HQ",      "GlobalCorp Inc")

# ---------------------------------------------------------------------------
# CLEAN: James Wilson – Retail Store Manager
# Biweekly payroll, rent, small personal purchases
# ---------------------------------------------------------------------------
ach.("TXN-JW-001", nil, acc_james,  2_800.00, 28.days.ago, "Payroll – RetailCo",     "RetailCo Inc")
ach.("TXN-JW-002", acc_james, nil,    950.00, 26.days.ago, "Rent payment",           "Phoenix Housing LLC")
ach.("TXN-JW-003", nil, acc_james,  2_800.00, 14.days.ago, "Payroll – RetailCo",     "RetailCo Inc")
ach.("TXN-JW-004", acc_james, nil,    200.00, 10.days.ago, "Credit card payment",    "Capital One Visa")
ach.("TXN-JW-005", acc_james, nil,     60.00,  5.days.ago, "Spotify / subscriptions","Spotify")

# ---------------------------------------------------------------------------
# CLEAN: Karen Moore – Dentist
# High professional income, mortgage, regular savings
# ---------------------------------------------------------------------------
ach.("TXN-KM-001", nil, acc_karen,   9_500.00, 30.days.ago, "Net pay – Dental Practice", "Moore Dental LLC")
ach.("TXN-KM-002", acc_karen, nil,   2_100.00, 28.days.ago, "Mortgage – home loan",      "Chase Mortgage")
ach.("TXN-KM-003", acc_karen, nil,   2_000.00, 27.days.ago, "401K contribution",         "Fidelity Investments")
ach.("TXN-KM-004", acc_karen, nil,     300.00, 20.days.ago, "Dental supply restock",     "Patterson Dental Supply")
ach.("TXN-KM-005", nil, acc_karen,   9_500.00,  1.day.ago,  "Net pay – Dental Practice", "Moore Dental LLC")

# ---------------------------------------------------------------------------
# CLEAN: Liam Thompson – IT Consultant
# Contract payments, co-working space, software subscriptions
# ---------------------------------------------------------------------------
ach.("TXN-LT-001", nil, acc_liam,    7_200.00, 29.days.ago, "Contract payment – Client A",  "Accenture LLC")
ach.("TXN-LT-002", acc_liam, nil,      400.00, 27.days.ago, "WeWork – co-working space",    "WeWork")
ach.("TXN-LT-003", acc_liam, nil,      150.00, 22.days.ago, "AWS + SaaS subscriptions",     "Amazon Web Services")
ach.("TXN-LT-004", nil, acc_liam,    6_800.00, 15.days.ago, "Contract payment – Client B",  "Deloitte Digital")
ach.("TXN-LT-005", acc_liam, nil,    1_000.00, 10.days.ago, "Estimated tax payment",        "IRS Direct Pay")

# ---------------------------------------------------------------------------
# CLEAN: Maria Santos – Restaurant Server
# Low income, small tips deposited in cash, occasional grocery ACH
# ---------------------------------------------------------------------------
deposit.("TXN-MS-001", acc_maria_s,   420.00, 28.days.ago, "Tips – cash deposit")
ach.("TXN-MS-002", nil, acc_maria_s,  980.00, 28.days.ago, "Payroll – Miami Grill",        "Miami Grill Restaurant")
deposit.("TXN-MS-003", acc_maria_s,   380.00, 21.days.ago, "Tips – cash deposit")
ach.("TXN-MS-004", nil, acc_maria_s,  980.00, 14.days.ago, "Payroll – Miami Grill",        "Miami Grill Restaurant")
deposit.("TXN-MS-005", acc_maria_s,   450.00,  7.days.ago, "Tips – cash deposit")

# ---------------------------------------------------------------------------
# CLEAN: Nathan Kim – Line Chef
# Modest biweekly payroll, small cash food/grocery purchases
# ---------------------------------------------------------------------------
ach.("TXN-NK-001", nil, acc_nathan,  1_800.00, 28.days.ago, "Payroll – The Grove Restaurant", "The Grove Restaurant")
ach.("TXN-NK-002", acc_nathan, nil,    600.00, 26.days.ago, "Rent – room share",              "Portland Rentals")
ach.("TXN-NK-003", nil, acc_nathan,  1_800.00, 14.days.ago, "Payroll – The Grove Restaurant", "The Grove Restaurant")
ach.("TXN-NK-004", acc_nathan, nil,     50.00,  5.days.ago, "Streaming services",             "Disney+")

# ---------------------------------------------------------------------------
# CLEAN: Olivia Brown – Graduate Student
# Student stipend, small Venmo transfers between friends, no suspicious activity
# ---------------------------------------------------------------------------
ach.("TXN-OB-001", nil, acc_olivia,  1_500.00, 30.days.ago, "Graduate stipend – MIT",  "MIT Financial Aid")
ach.("TXN-OB-002", nil, acc_olivia,    200.00, 28.days.ago, "Venmo – friend split",    "Venmo / PayPal")
ach.("TXN-OB-003", acc_olivia, nil,    650.00, 25.days.ago, "Rent – student housing",  "MIT Housing Office")
ach.("TXN-OB-004", nil, acc_olivia,  1_500.00,  1.day.ago,  "Graduate stipend – MIT",  "MIT Financial Aid")

puts "Seeding alerts..."

# =============================================================================
# ALERTS  (manually seeded for demonstration; AlertDetectionService generates
#          these in production from real transaction data)
# =============================================================================

Alert.create!(
  alert_id: "AML-2024-001", alert_type: "Structured Cash Deposits (Smurfing)",
  severity: "high", status: "open",
  customer: carlos, account: acc_carlos,
  description: "Five cash deposits totaling $48,550 made over 14 days, each deliberately "\
               "below the $10,000 CTR threshold. Pattern is consistent with structuring "\
               "under 31 U.S.C. § 5324.",
  rule_triggered: "LARGE_AMOUNT",
  txn_refs: %w[TXN-CM-001 TXN-CM-002 TXN-CM-003 TXN-CM-004 TXN-CM-005],
  metadata: {
    total_amount: 48_550.00, avg_transaction: 9_710.00,
    threshold_avoidance: "$100–$500 below CTR threshold", pattern: "Structuring",
    risk_indicators: ["Sub-threshold deposits", "14-day pattern", "Import/Export occupation"]
  }
)

Alert.create!(
  alert_id: "AML-2024-002", alert_type: "Rapid Fund Movement / Pass-Through Layering",
  severity: "critical", status: "open",
  customer: bright, account: acc_bright,
  description: "Bright Future LLC received a $500,000 international wire from Cayman Islands. "\
               "Within 48 hours, $455,000 was distributed to five separate accounts in "\
               "sub-$100K tranches. Classic funnel-and-distribute layering pattern.",
  rule_triggered: "LARGE_AMOUNT",
  txn_refs: %w[TXN-BF-001 TXN-BF-002 TXN-BF-003 TXN-BF-004 TXN-BF-005 TXN-BF-006],
  metadata: {
    inbound_amount: 500_000.00, outbound_amount: 455_000.00,
    time_to_distribute: "48 hours", recipients: 5,
    originator_jurisdiction: "Cayman Islands",
    risk_indicators: ["Offshore wire origin", "Rapid re-distribution", "Cayman jurisdiction"]
  }
)

Alert.create!(
  alert_id: "AML-2024-003", alert_type: "PEP Suspicious Wire Transfer",
  severity: "critical", status: "open",
  customer: emmanuel, account: acc_emmanuel,
  description: "Retired Nigerian government minister received $450,000 wire from Cyprus-registered "\
               "advisory firm. Funds rapidly redistributed to a Swiss trust and via cash withdrawal. "\
               "PEP status requires enhanced scrutiny.",
  rule_triggered: "LARGE_AMOUNT",
  txn_refs: %w[TXN-EO-001 TXN-EO-002 TXN-EO-003 TXN-EO-004],
  metadata: {
    pep_status: true, originator_jurisdiction: "Cyprus",
    risk_indicators: ["Politically Exposed Person", "Enhanced Due Diligence required",
                      "Offshore wire (Cyprus)", "Redistribution to Swiss trust", "Large cash withdrawal"]
  }
)

Alert.create!(
  alert_id: "AML-2024-004", alert_type: "Dormant Account Sudden Activation",
  severity: "high", status: "open",
  customer: sarah, account: acc_sarah,
  description: "Savings account dormant 3+ years received a $220,000 wire from HK law firm. "\
               "Within 5 days, $150,000 was redistributed via wire and cash withdrawal. "\
               "Account holder is a 79-year-old retired teacher.",
  rule_triggered: "DORMANT_ACTIVITY",
  txn_refs: %w[TXN-SC-001 TXN-SC-002 TXN-SC-003],
  metadata: {
    dormant_period: "3+ years", inbound_amount: 220_000.00, redistribution: 150_000.00,
    risk_indicators: ["Dormant 3+ years", "Large wire deposit", "Rapid redistribution",
                      "Elderly account holder – possible exploitation"]
  }
)

Alert.create!(
  alert_id: "AML-2024-005", alert_type: "Unusual Cash Deposit Volume – Business Account",
  severity: "high", status: "open",
  customer: golden, account: acc_golden,
  description: "Golden Dragon has made weekly cash deposits of $52K–$63.5K for 6 weeks, "\
               "totaling $349,100. Historical baseline was $5K–$8K/week. No business event "\
               "explains a 700% spike.",
  rule_triggered: "LARGE_AMOUNT",
  txn_refs: %w[TXN-GD-001 TXN-GD-002 TXN-GD-003 TXN-GD-004 TXN-GD-005 TXN-GD-006],
  metadata: {
    total_deposits: 349_100.00, avg_weekly_current: 58_183.00, avg_weekly_historical: 6_500.00,
    risk_indicators: ["700% volume spike", "Cash-intensive business", "No seasonal explanation"]
  }
)

Alert.create!(
  alert_id: "AML-2024-006", alert_type: "Funnel Account Activity",
  severity: "high", status: "open",
  customer: marcus, account: acc_marcus,
  description: "Marcus Williams received 12 ACH transfers totaling $24,500 from unrelated parties "\
               "over 12 days, then withdrew the entire balance in cash the following day. "\
               "Occupation and account history are inconsistent with this volume.",
  rule_triggered: "HIGH_FREQUENCY",
  txn_refs: %w[TXN-MW-001 TXN-MW-002 TXN-MW-003 TXN-MW-004 TXN-MW-005 TXN-MW-006
               TXN-MW-007 TXN-MW-008 TXN-MW-009 TXN-MW-010 TXN-MW-011 TXN-MW-012 TXN-MW-013],
  metadata: {
    inbound_total: 24_500.00, cash_withdrawal: 24_500.00, sender_count: 12,
    risk_indicators: ["Multiple unrelated senders", "Exact balance cleared", "Income mismatch"]
  }
)

Alert.create!(
  alert_id: "AML-2024-007", alert_type: "Coordinated Smurfing Deposits",
  severity: "high", status: "open",
  customer: victor, account: acc_victor,
  description: "Three low-income individuals (day laborer, cleaner, construction worker) made "\
               "coordinated same-day deposits to Victor Salinas's account on two occasions, "\
               "totaling $54,100. Funds were wired to Panama the following day.",
  rule_triggered: "HIGH_FREQUENCY",
  txn_refs: %w[TXN-SM-001 TXN-SM-002 TXN-SM-003 TXN-SM-004 TXN-SM-005 TXN-SM-006 TXN-SM-007],
  metadata: {
    smurf_count: 3, total_collected: 54_100.00, destination: "Panama",
    risk_indicators: ["Coordinated low-income depositors", "Same-day pattern", "Panama wire outbound"]
  }
)

Alert.create!(
  alert_id: "AML-2024-008", alert_type: "Round-Dollar Wire Pattern",
  severity: "medium", status: "open",
  customer: apex, account: acc_apex,
  description: "Apex Capital Partners made 7 identical $50,000 outbound wires to BVI entities "\
               "over 3 weeks. Round-dollar amounts with generic references indicate possible "\
               "structured layering.",
  rule_triggered: "LARGE_AMOUNT",
  txn_refs: %w[TXN-AP-001 TXN-AP-002 TXN-AP-003 TXN-AP-004 TXN-AP-005 TXN-AP-006 TXN-AP-007],
  metadata: {
    total_outbound: 350_000.00, wire_count: 7, destination_jurisdiction: "British Virgin Islands",
    risk_indicators: ["Identical round-dollar amounts", "BVI destination", "Generic memo fields"]
  }
)

Alert.create!(
  alert_id: "AML-2024-009", alert_type: "Crypto-to-Fiat Conversion with Foreign Layering",
  severity: "high", status: "open",
  customer: dimitri, account: acc_dimitri,
  description: "Dimitri Volkov deposited $225,000 from cryptocurrency exchanges over 5 weeks, "\
               "then wired $200,000 to an Estonian crypto firm and a Russian family fund. "\
               "High-risk nationality with EDD requirement.",
  rule_triggered: "UNUSUAL_GEOGRAPHY",
  txn_refs: %w[TXN-DV-001 TXN-DV-002 TXN-DV-003 TXN-DV-004 TXN-DV-005 TXN-DV-006 TXN-DV-007],
  metadata: {
    crypto_deposits: 225_000.00, outbound_wires: 200_000.00,
    destinations: ["Estonia", "Russia"],
    risk_indicators: ["Russian national – EDD", "Crypto source of funds", "Wire to RU entity"]
  }
)

Alert.create!(
  alert_id: "AML-2024-010", alert_type: "Trade-Based Money Laundering",
  severity: "critical", status: "open",
  customer: silk, account: acc_silk,
  description: "Silk Road Trading Co. received $1.35M in wire transfers from Chinese counterparties "\
               "significantly exceeding declared invoice values, then made a $1.1M consolidated "\
               "outbound wire to a Hong Kong entity within 2 months.",
  rule_triggered: "UNUSUAL_GEOGRAPHY",
  txn_refs: %w[TXN-SR-001 TXN-SR-002 TXN-SR-003 TXN-SR-004 TXN-SR-005 TXN-SR-006],
  metadata: {
    total_inbound: 1_350_000.00, total_outbound: 1_100_000.00,
    risk_indicators: ["Over-invoicing pattern", "Chinese counterparties", "HK consolidation wire"]
  }
)

Alert.create!(
  alert_id: "AML-2024-011", alert_type: "High Transaction Frequency – Money Services Business",
  severity: "high", status: "open",
  customer: rapid_cash, account: acc_rapid,
  description: "Rapid Cash Exchange LLC processed 14 transactions in a single 7-hour window, "\
               "cycling $220,500 through the account. Pattern is consistent with rapid "\
               "pass-through by an unlicensed money services business.",
  rule_triggered: "HIGH_FREQUENCY",
  txn_refs: (1..14).map { |i| "TXN-RC-#{i.to_s.rjust(3, '0')}" },
  metadata: {
    transaction_count: 14, window_hours: 7, total_cycled: 220_500.00,
    risk_indicators: ["14 txns in 7 hours", "Money services profile", "Rapid in-out cycling"]
  }
)

Alert.create!(
  alert_id: "AML-2024-012", alert_type: "Transactions with Sanctioned Jurisdictions",
  severity: "critical", status: "open",
  customer: omar, account: acc_omar,
  description: "Omar Trade International received wires from Iran (IR) and North Korea (KP) "\
               "and sent to Syria (SY) — all OFAC-sanctioned jurisdictions. Total exposure: "\
               "$550,000 over 4 days.",
  rule_triggered: "UNUSUAL_GEOGRAPHY",
  txn_refs: %w[TXN-OT-001 TXN-OT-002 TXN-OT-003 TXN-OT-004],
  metadata: {
    sanctioned_countries: %w[IR KP SY], total_exposure: 550_000.00,
    risk_indicators: ["OFAC-sanctioned jurisdiction exposure", "Iran, Syria, N.Korea", "EDD required"]
  }
)

Alert.create!(
  alert_id: "AML-2024-013", alert_type: "PEP – High-Risk Jurisdiction Wire Network",
  severity: "critical", status: "open",
  customer: pavel, account: acc_pavel,
  description: "Pavel Ivanov (Russian PEP, energy executive) received $470,000 from Cyprus "\
               "and Belize, then routed $455,000 to Russia, North Korea, and Belarus entities "\
               "within 7 days. Pattern consistent with sanctions evasion.",
  rule_triggered: "UNUSUAL_GEOGRAPHY",
  txn_refs: %w[TXN-PI-001 TXN-PI-002 TXN-PI-003 TXN-PI-004 TXN-PI-005],
  metadata: {
    inbound: 470_000.00, outbound: 455_000.00,
    high_risk_countries: %w[RU KP BY CY BZ],
    risk_indicators: ["Russian PEP", "KP/RU/BY destinations", "Sanctions evasion indicators"]
  }
)

Alert.create!(
  alert_id: "AML-2024-014", alert_type: "Crypto Mixer Proceeds – Sanctioned Jurisdiction Routing",
  severity: "critical", status: "open",
  customer: anastasia, account: acc_anastasia,
  description: "Anastasia Petrov deposited $223,000 originating from a known crypto mixer "\
               "(Tornado Cash) then wired $180,000 to entities in North Korea, Iran, and Syria "\
               "— all OFAC-sanctioned countries.",
  rule_triggered: "UNUSUAL_GEOGRAPHY",
  txn_refs: %w[TXN-AP2-001 TXN-AP2-002 TXN-AP2-003 TXN-AP2-004 TXN-AP2-005 TXN-AP2-006],
  metadata: {
    crypto_source: "Tornado Cash mixer", total_deposited: 223_000.00, total_outbound: 180_000.00,
    sanctioned_destinations: %w[KP IR SY],
    risk_indicators: ["Tornado Cash origin", "Three sanctioned jurisdictions", "Russian national EDD"]
  }
)

Alert.create!(
  alert_id: "AML-2024-015", alert_type: "Dormant Business Account Reactivation",
  severity: "high", status: "open",
  customer: legacy, account: acc_legacy,
  description: "Legacy Industries LLC business account was dormant for 4+ years. It suddenly "\
               "received a $400,000 wire from a Cayman offshore entity and redistributed "\
               "$390,000 to shell vendors in Belize and Panama within 6 days.",
  rule_triggered: "DORMANT_ACTIVITY",
  txn_refs: %w[TXN-LI-001 TXN-LI-002 TXN-LI-003 TXN-LI-004],
  metadata: {
    dormant_years: 4, inbound: 400_000.00, outbound: 390_000.00,
    risk_indicators: ["4-year dormant period", "Cayman origin", "Shell vendor payments", "BZ/PA routing"]
  }
)

Alert.create!(
  alert_id: "AML-2024-016", alert_type: "Cumulative Structuring – Multiple Sub-Threshold Wires",
  severity: "high", status: "open",
  customer: roberto, account: acc_roberto,
  description: "Roberto Villa made 6 outbound wire transfers totaling $76,700 over 25 days, "\
               "each individually below $15,000, to offshore entities in Panama, Venezuela, "\
               "Cayman Islands, and Belize. Cumulative total exceeds the $50,000 monitoring "\
               "threshold with no credible business explanation.",
  rule_triggered: "LARGE_AMOUNT",
  txn_refs: %w[TXN-RV-001 TXN-RV-002 TXN-RV-003 TXN-RV-004 TXN-RV-005 TXN-RV-006],
  metadata: {
    cumulative_30d_outbound: 76_700.00, wire_count: 6,
    destinations: %w[US PA VE KY BZ],
    risk_indicators: ["Sub-threshold individual wires", "Cumulative > $50K", "Offshore routing"]
  }
)

puts ""
puts "=" * 60
puts "  Seed complete!"
puts "=" * 60
puts "  Customers  : #{Customer.count} (#{Customer.where(risk_score: 60..).count} high-risk)"
puts "  Accounts   : #{Account.count} (#{Account.where(status: 'dormant').count} dormant, #{Account.where(status: 'closed').count} closed)"
puts "  Transactions: #{FinancialTransaction.count}"
puts "  Alerts     : #{Alert.count} (#{Alert.where(severity: %w[critical high]).count} critical/high)"
puts "=" * 60
puts ""
puts "  AML accounts  : 28  (scenarios 1–16)"
puts "  Clean accounts: 27  (Alice, Bob, Carol, David, Emma, Frank,"
puts "                        Grace, Henry, Isabella, James, Karen,"
puts "                        Liam, Maria, Nathan, Olivia + savings)"
puts "=" * 60
