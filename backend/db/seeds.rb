# =============================================================================
# AML Autopilot – Seed Data
# 10 realistic AML typologies, 15 customers, 22 accounts, 150+ transactions
# Based on FinCEN typologies and FATF guidance
# =============================================================================

puts "Clearing existing seed data..."
Alert.destroy_all
FinancialTransaction.destroy_all
Account.destroy_all
Customer.destroy_all

puts "Seeding customers..."

# ---------------------------------------------------------------------------
# CUSTOMERS
# ---------------------------------------------------------------------------
carlos    = Customer.create!(customer_id: "CUST_001", name: "Carlos Mendez",
              email: "cmendez@email.com", phone: "+1-305-555-0101",
              nationality: "MX", country_of_residence: "US",
              occupation: "Import/Export Consultant", date_of_birth: "1975-03-15",
              risk_score: 78, kyc_status: "verified", is_pep: false)

emmanuel  = Customer.create!(customer_id: "CUST_002", name: "Emmanuel Okafor",
              email: "e.okafor@govoffice.ng", phone: "+1-202-555-0102",
              nationality: "NG", country_of_residence: "US",
              occupation: "Government Minister (retired)", date_of_birth: "1968-11-20",
              risk_score: 92, kyc_status: "enhanced_due_diligence", is_pep: true)

bright    = Customer.create!(customer_id: "CUST_003", name: "Bright Future LLC",
              email: "admin@brightfuturellc.com", phone: "+1-212-555-0103",
              nationality: "US", country_of_residence: "US",
              occupation: "Investment Holding Company", date_of_birth: nil,
              risk_score: 85, kyc_status: "verified", is_pep: false)

sarah     = Customer.create!(customer_id: "CUST_004", name: "Sarah Chen",
              email: "schen@yahoo.com", phone: "+1-718-555-0104",
              nationality: "US", country_of_residence: "US",
              occupation: "Retired Teacher", date_of_birth: "1945-07-08",
              risk_score: 40, kyc_status: "verified", is_pep: false)

golden    = Customer.create!(customer_id: "CUST_005", name: "Golden Dragon Restaurant Group",
              email: "finance@goldendragon.biz", phone: "+1-415-555-0105",
              nationality: "US", country_of_residence: "US",
              occupation: "Restaurant / Food Service", date_of_birth: nil,
              risk_score: 62, kyc_status: "verified", is_pep: false)

marcus    = Customer.create!(customer_id: "CUST_006", name: "Marcus Williams",
              email: "mwilliams@fastmail.com", phone: "+1-404-555-0106",
              nationality: "US", country_of_residence: "US",
              occupation: "Freelance Contractor", date_of_birth: "1990-05-22",
              risk_score: 71, kyc_status: "verified", is_pep: false)

apex      = Customer.create!(customer_id: "CUST_007", name: "Apex Capital Partners LLC",
              email: "transactions@apexcapital.com", phone: "+1-646-555-0107",
              nationality: "US", country_of_residence: "US",
              occupation: "Private Equity / Investment", date_of_birth: nil,
              risk_score: 68, kyc_status: "verified", is_pep: false)

dimitri   = Customer.create!(customer_id: "CUST_008", name: "Dimitri Volkov",
              email: "dvolkov@protonmail.com", phone: "+1-917-555-0108",
              nationality: "RU", country_of_residence: "US",
              occupation: "Cryptocurrency Trader", date_of_birth: "1985-04-17",
              risk_score: 88, kyc_status: "enhanced_due_diligence", is_pep: false)

silk      = Customer.create!(customer_id: "CUST_009", name: "Silk Road Trading Co.",
              email: "ops@silkroadtrading.net", phone: "+1-213-555-0109",
              nationality: "CN", country_of_residence: "US",
              occupation: "Import / Export Trading", date_of_birth: nil,
              risk_score: 80, kyc_status: "enhanced_due_diligence", is_pep: false)

hassan    = Customer.create!(customer_id: "CUST_010", name: "Hassan Al-Rashid",
              email: "h.alrashid@businessemail.ae", phone: "+1-310-555-0110",
              nationality: "AE", country_of_residence: "US",
              occupation: "Real Estate Developer", date_of_birth: "1972-01-25",
              risk_score: 73, kyc_status: "verified", is_pep: false)

diego     = Customer.create!(customer_id: "CUST_011", name: "Diego Ramirez",
              email: "dramirez@gmail.com", phone: "+1-786-555-0111",
              nationality: "CO", country_of_residence: "US",
              occupation: "Day Laborer", date_of_birth: "1995-02-10",
              risk_score: 55, kyc_status: "verified", is_pep: false)

ana       = Customer.create!(customer_id: "CUST_012", name: "Ana Torres",
              email: "atorres@hotmail.com", phone: "+1-786-555-0112",
              nationality: "CO", country_of_residence: "US",
              occupation: "Cleaning Services", date_of_birth: "1993-08-30",
              risk_score: 52, kyc_status: "verified", is_pep: false)

luis      = Customer.create!(customer_id: "CUST_013", name: "Luis Vargas",
              email: "lvargas@email.com", phone: "+1-786-555-0113",
              nationality: "MX", country_of_residence: "US",
              occupation: "Construction Worker", date_of_birth: "1991-12-05",
              risk_score: 50, kyc_status: "verified", is_pep: false)

# Recipient account for smurfing deposits
victor    = Customer.create!(customer_id: "CUST_014", name: "Victor Salinas",
              email: "vsalinas@mailbox.com", phone: "+1-786-555-0114",
              nationality: "CO", country_of_residence: "US",
              occupation: "Used Car Dealer", date_of_birth: "1982-06-18",
              risk_score: 76, kyc_status: "verified", is_pep: false)

# Internal counterparty accounts (normal customers)
jennifer  = Customer.create!(customer_id: "CUST_015", name: "Jennifer Park",
              email: "jpark@corp.com", phone: "+1-408-555-0115",
              nationality: "US", country_of_residence: "US",
              occupation: "Software Engineer", date_of_birth: "1988-09-14",
              risk_score: 10, kyc_status: "verified", is_pep: false)

puts "Seeding accounts..."

# ---------------------------------------------------------------------------
# ACCOUNTS
# ---------------------------------------------------------------------------
acc_carlos   = Account.create!(customer: carlos,   account_number: "CHK-CM-001",  account_type: "checking",   balance: 12_450.00, currency: "USD", status: "active",  branch: "Miami Downtown",   opened_at: "2019-04-10")
acc_emmanuel = Account.create!(customer: emmanuel,  account_number: "CHK-EO-001",  account_type: "checking",   balance: 498_250.00, currency: "USD", status: "active", branch: "Washington DC",    opened_at: "2020-01-15")
acc_bright   = Account.create!(customer: bright,    account_number: "BIZ-BFL-001", account_type: "business",   balance: 28_000.00, currency: "USD", status: "active",  branch: "New York Midtown", opened_at: "2021-06-01")
acc_sarah    = Account.create!(customer: sarah,     account_number: "SAV-SC-001",  account_type: "savings",    balance: 220_000.00, currency: "USD", status: "dormant", branch: "Brooklyn",        opened_at: "2008-03-22")
acc_golden   = Account.create!(customer: golden,    account_number: "BIZ-GDR-001", account_type: "business",   balance: 185_000.00, currency: "USD", status: "active", branch: "San Francisco",    opened_at: "2016-09-05")
acc_marcus   = Account.create!(customer: marcus,    account_number: "CHK-MW-001",  account_type: "checking",   balance: 4_200.00,  currency: "USD", status: "active",  branch: "Atlanta",          opened_at: "2018-11-30")
acc_apex     = Account.create!(customer: apex,      account_number: "BIZ-ACP-001", account_type: "business",   balance: 750_000.00, currency: "USD", status: "active", branch: "New York Wall St", opened_at: "2017-02-14")
acc_dimitri  = Account.create!(customer: dimitri,   account_number: "CHK-DV-001",  account_type: "checking",   balance: 95_000.00, currency: "USD", status: "active",  branch: "New York",         opened_at: "2022-07-20")
acc_silk     = Account.create!(customer: silk,      account_number: "BIZ-SR-001",  account_type: "business",   balance: 340_000.00, currency: "USD", status: "active", branch: "Los Angeles",      opened_at: "2020-03-18")
acc_hassan   = Account.create!(customer: hassan,    account_number: "CHK-HA-001",  account_type: "checking",   balance: 55_000.00, currency: "USD", status: "active",  branch: "Beverly Hills",    opened_at: "2021-10-01")
acc_diego    = Account.create!(customer: diego,     account_number: "CHK-DR-001",  account_type: "checking",   balance: 800.00,   currency: "USD", status: "active",   branch: "Miami",            opened_at: "2023-01-10")
acc_ana      = Account.create!(customer: ana,       account_number: "CHK-AT-001",  account_type: "checking",   balance: 650.00,   currency: "USD", status: "active",   branch: "Miami",            opened_at: "2023-03-05")
acc_luis     = Account.create!(customer: luis,      account_number: "CHK-LV-001",  account_type: "checking",   balance: 720.00,   currency: "USD", status: "active",   branch: "Miami",            opened_at: "2023-06-15")
acc_victor   = Account.create!(customer: victor,    account_number: "CHK-VS-001",  account_type: "checking",   balance: 82_000.00, currency: "USD", status: "active",  branch: "Miami",            opened_at: "2021-05-20")
acc_jennifer = Account.create!(customer: jennifer,  account_number: "CHK-JP-001",  account_type: "checking",   balance: 18_500.00, currency: "USD", status: "active",  branch: "San Jose",         opened_at: "2020-08-12")

# Bright Future distribution accounts (recipients of pass-through)
acc_bright2  = Account.create!(customer: bright,   account_number: "BIZ-BFL-002",  account_type: "business",  balance: 0.00, currency: "USD", status: "closed",  branch: "New York",  opened_at: "2021-06-01")
acc_apex2    = Account.create!(customer: apex,     account_number: "BIZ-ACP-002",  account_type: "business",  balance: 0.00, currency: "USD", status: "active",  branch: "New York",  opened_at: "2022-01-10")
acc_hassan2  = Account.create!(customer: hassan,   account_number: "SAV-HA-001",   account_type: "savings",   balance: 0.00, currency: "USD", status: "active",  branch: "Beverly Hills", opened_at: "2023-04-01")
acc_dimitri2 = Account.create!(customer: dimitri,  account_number: "SAV-DV-001",   account_type: "savings",   balance: 0.00, currency: "USD", status: "active",  branch: "New York",  opened_at: "2023-05-01")
acc_marcus2  = Account.create!(customer: marcus,   account_number: "SAV-MW-001",   account_type: "savings",   balance: 0.00, currency: "USD", status: "active",  branch: "Atlanta",   opened_at: "2023-06-01")
acc_silk2    = Account.create!(customer: silk,     account_number: "BIZ-SR-002",   account_type: "business",  balance: 0.00, currency: "USD", status: "active",  branch: "Los Angeles", opened_at: "2023-07-01")
acc_carlos2  = Account.create!(customer: carlos,   account_number: "SAV-CM-001",   account_type: "savings",   balance: 0.00, currency: "USD", status: "active",  branch: "Miami",     opened_at: "2023-08-01")

puts "Seeding transactions..."

txns = {}

# ---------------------------------------------------------------------------
# SCENARIO 1: STRUCTURING / SMURFING – Carlos Mendez
# Multiple cash deposits just below the $10,000 CTR threshold over 14 days
# ---------------------------------------------------------------------------
t = ->(ref, acct, amt, date, desc) {
  FinancialTransaction.create!(
    txn_ref: ref, to_account: acct, amount: amt, currency: "USD",
    txn_type: "cash_deposit", description: desc, location: "Miami, FL",
    counterparty_name: "Cash Deposit – Branch Teller",
    transacted_at: DateTime.parse(date)
  )
}

txns[:cm1]  = t.("TXN-CM-001", acc_carlos, 9_800.00, "2024-10-01 10:15", "Cash deposit – personal savings")
txns[:cm2]  = t.("TXN-CM-002", acc_carlos, 9_750.00, "2024-10-04 14:30", "Cash deposit")
txns[:cm3]  = t.("TXN-CM-003", acc_carlos, 9_500.00, "2024-10-07 09:45", "Cash deposit – consulting fee")
txns[:cm4]  = t.("TXN-CM-004", acc_carlos, 9_900.00, "2024-10-10 11:00", "Cash deposit")
txns[:cm5]  = t.("TXN-CM-005", acc_carlos, 9_600.00, "2024-10-14 16:20", "Cash deposit – misc income")

# ---------------------------------------------------------------------------
# SCENARIO 2: RAPID PASS-THROUGH / LAYERING – Bright Future LLC
# $500K offshore wire in; $455K distributed to 5 accounts within 48 hours
# ---------------------------------------------------------------------------
txns[:bf1]  = FinancialTransaction.create!(
  txn_ref: "TXN-BF-001", to_account: acc_bright, amount: 500_000.00, currency: "USD",
  txn_type: "wire_transfer", description: "Incoming international wire – investment capital",
  location: "New York, NY", counterparty_name: "Cayman Holdings Ltd.",
  counterparty_country: "KY", transacted_at: DateTime.parse("2024-10-15 08:00")
)
txns[:bf2]  = FinancialTransaction.create!(txn_ref: "TXN-BF-002", from_account: acc_bright, to_account: acc_apex,     amount: 90_000.00, currency: "USD", txn_type: "wire_transfer",  description: "Transfer – project funding",    location: "New York, NY", transacted_at: DateTime.parse("2024-10-15 14:10"))
txns[:bf3]  = FinancialTransaction.create!(txn_ref: "TXN-BF-003", from_account: acc_bright, to_account: acc_hassan,   amount: 85_000.00, currency: "USD", txn_type: "wire_transfer",  description: "Transfer – consulting retainer", location: "New York, NY", transacted_at: DateTime.parse("2024-10-15 16:30"))
txns[:bf4]  = FinancialTransaction.create!(txn_ref: "TXN-BF-004", from_account: acc_bright, to_account: acc_dimitri,  amount: 100_000.00, currency: "USD", txn_type: "wire_transfer", description: "Transfer – investment tranche",  location: "New York, NY", transacted_at: DateTime.parse("2024-10-16 09:15"))
txns[:bf5]  = FinancialTransaction.create!(txn_ref: "TXN-BF-005", from_account: acc_bright, to_account: acc_marcus,   amount: 95_000.00, currency: "USD", txn_type: "wire_transfer",  description: "Transfer – service fees",       location: "New York, NY", transacted_at: DateTime.parse("2024-10-16 11:00"))
txns[:bf6]  = FinancialTransaction.create!(txn_ref: "TXN-BF-006", from_account: acc_bright, to_account: acc_silk,     amount: 85_000.00, currency: "USD", txn_type: "wire_transfer",  description: "Transfer – vendor payment",     location: "New York, NY", transacted_at: DateTime.parse("2024-10-16 13:45"))

# ---------------------------------------------------------------------------
# SCENARIO 3: PEP SUSPICIOUS WIRE – Emmanuel Okafor
# Retired government minister receives $450K from unknown offshore entity
# ---------------------------------------------------------------------------
txns[:eo1]  = FinancialTransaction.create!(
  txn_ref: "TXN-EO-001", to_account: acc_emmanuel, amount: 450_000.00, currency: "USD",
  txn_type: "wire_transfer", description: "International wire – advisory compensation",
  location: "Washington, DC", counterparty_name: "Meridian Global Advisors Ltd.",
  counterparty_country: "CY", transacted_at: DateTime.parse("2024-09-20 11:30")
)
txns[:eo2]  = FinancialTransaction.create!(
  txn_ref: "TXN-EO-002", from_account: acc_emmanuel, amount: 200_000.00, currency: "USD",
  txn_type: "wire_transfer", description: "Transfer – real estate escrow",
  location: "Washington, DC", counterparty_name: "DC Metro Realty Trust",
  transacted_at: DateTime.parse("2024-09-22 14:00")
)
txns[:eo3]  = FinancialTransaction.create!(
  txn_ref: "TXN-EO-003", from_account: acc_emmanuel, amount: 150_000.00, currency: "USD",
  txn_type: "wire_transfer", description: "Transfer – Okafor Family Trust account",
  location: "Washington, DC", counterparty_name: "Okafor Family Trust",
  counterparty_country: "CH", transacted_at: DateTime.parse("2024-09-25 09:15")
)
txns[:eo4]  = FinancialTransaction.create!(
  txn_ref: "TXN-EO-004", from_account: acc_emmanuel, amount: 80_000.00, currency: "USD",
  txn_type: "cash_withdrawal", description: "Cash withdrawal",
  location: "Washington, DC", transacted_at: DateTime.parse("2024-09-28 10:00")
)

# ---------------------------------------------------------------------------
# SCENARIO 4: FUNNEL ACCOUNT – Marcus Williams
# Many small inbound transfers; one large cash withdrawal
# ---------------------------------------------------------------------------
funnel_senders = [
  ["TXN-MW-001", "2024-11-01 09:00", 1_800.00, "Payment for services – Invoice #1042"],
  ["TXN-MW-002", "2024-11-02 11:30", 2_400.00, "Freelance project payment"],
  ["TXN-MW-003", "2024-11-03 14:15", 1_950.00, "Consulting fee"],
  ["TXN-MW-004", "2024-11-04 10:00", 2_200.00, "Project deliverable payment"],
  ["TXN-MW-005", "2024-11-05 16:30", 1_700.00, "Service payment – Nov batch"],
  ["TXN-MW-006", "2024-11-06 09:45", 2_500.00, "Freelance – web development"],
  ["TXN-MW-007", "2024-11-07 13:00", 1_850.00, "Payment ref: INV-2024-1107"],
  ["TXN-MW-008", "2024-11-08 11:15", 2_100.00, "Consulting retainer"],
  ["TXN-MW-009", "2024-11-09 14:45", 1_900.00, "Project completion bonus"],
  ["TXN-MW-010", "2024-11-10 10:30", 2_300.00, "Service fee – final payment"],
  ["TXN-MW-011", "2024-11-11 12:00", 1_750.00, "Freelance payment"],
  ["TXN-MW-012", "2024-11-12 15:30", 2_050.00, "Invoice settlement"],
]

funnel_senders.each do |ref, date, amt, desc|
  txns[ref.to_sym] = FinancialTransaction.create!(
    txn_ref: ref, to_account: acc_marcus, amount: amt, currency: "USD",
    txn_type: "ach_transfer", description: desc, location: "Atlanta, GA",
    counterparty_name: "Various Payers (see description)",
    transacted_at: DateTime.parse(date)
  )
end

txns[:mw_w]  = FinancialTransaction.create!(
  txn_ref: "TXN-MW-013", from_account: acc_marcus, amount: 26_500.00, currency: "USD",
  txn_type: "cash_withdrawal", description: "ATM / branch cash withdrawal",
  location: "Atlanta, GA", transacted_at: DateTime.parse("2024-11-13 09:00")
)

# ---------------------------------------------------------------------------
# SCENARIO 5: DORMANT ACCOUNT ACTIVATION – Sarah Chen
# Account inactive 3+ years; suddenly receives $220K wire
# ---------------------------------------------------------------------------
txns[:sc1]   = FinancialTransaction.create!(
  txn_ref: "TXN-SC-001", to_account: acc_sarah, amount: 220_000.00, currency: "USD",
  txn_type: "wire_transfer", description: "Wire transfer – estate settlement proceeds",
  location: "Brooklyn, NY", counterparty_name: "Pacific Rim Law Group",
  counterparty_country: "HK", transacted_at: DateTime.parse("2024-10-25 10:30")
)
txns[:sc2]   = FinancialTransaction.create!(
  txn_ref: "TXN-SC-002", from_account: acc_sarah, amount: 100_000.00, currency: "USD",
  txn_type: "wire_transfer", description: "Transfer – investment account",
  location: "Brooklyn, NY", counterparty_name: "Unknown Brokerage – Account 9927",
  transacted_at: DateTime.parse("2024-10-28 14:15")
)
txns[:sc3]   = FinancialTransaction.create!(
  txn_ref: "TXN-SC-003", from_account: acc_sarah, amount: 50_000.00, currency: "USD",
  txn_type: "cash_withdrawal", description: "Cash withdrawal",
  location: "Brooklyn, NY", transacted_at: DateTime.parse("2024-10-30 11:00")
)

# ---------------------------------------------------------------------------
# SCENARIO 6: CASH-INTENSIVE BUSINESS ABUSE – Golden Dragon Restaurant Group
# Restaurant deposits $50K-$65K/week vs. $5K-$8K historical baseline
# ---------------------------------------------------------------------------
cash_deposits_golden = [
  ["TXN-GD-001", "2024-09-02 17:00", 52_400.00],
  ["TXN-GD-002", "2024-09-09 17:30", 61_800.00],
  ["TXN-GD-003", "2024-09-16 17:00", 58_200.00],
  ["TXN-GD-004", "2024-09-23 16:45", 63_500.00],
  ["TXN-GD-005", "2024-09-30 17:15", 55_900.00],
  ["TXN-GD-006", "2024-10-07 17:00", 57_300.00],
]

cash_deposits_golden.each do |ref, date, amt|
  txns[ref.to_sym] = FinancialTransaction.create!(
    txn_ref: ref, to_account: acc_golden, amount: amt, currency: "USD",
    txn_type: "cash_deposit", description: "Weekly restaurant cash revenue deposit",
    location: "San Francisco, CA", counterparty_name: "Cash – Branch Teller",
    transacted_at: DateTime.parse(date)
  )
end

# ---------------------------------------------------------------------------
# SCENARIO 7: SMURFING (COORDINATED DEPOSITS) – Diego, Ana, Luis → Victor
# Three low-income individuals make same-day deposits to Victor Salinas
# ---------------------------------------------------------------------------
smurf_txns = [
  ["TXN-SM-001", acc_diego,  9_100.00, "2024-11-18 09:10", "Payment to VS"],
  ["TXN-SM-002", acc_ana,    8_900.00, "2024-11-18 09:45", "Transfer to Victor"],
  ["TXN-SM-003", acc_luis,   9_400.00, "2024-11-18 10:20", "Funds transfer"],
  ["TXN-SM-004", acc_diego,  8_800.00, "2024-11-25 09:05", "Payment – Nov 2"],
  ["TXN-SM-005", acc_ana,    9_200.00, "2024-11-25 10:15", "Transfer – personal"],
  ["TXN-SM-006", acc_luis,   8_700.00, "2024-11-25 11:30", "Funds movement"],
]

smurf_txns.each do |ref, from_acc, amt, date, desc|
  txns[ref.to_sym] = FinancialTransaction.create!(
    txn_ref: ref, from_account: from_acc, to_account: acc_victor,
    amount: amt, currency: "USD", txn_type: "ach_transfer",
    description: desc, location: "Miami, FL",
    transacted_at: DateTime.parse(date)
  )
end

txns[:sm_out] = FinancialTransaction.create!(
  txn_ref: "TXN-SM-007", from_account: acc_victor, amount: 54_100.00, currency: "USD",
  txn_type: "wire_transfer", description: "Wire – vehicle purchase settlement",
  location: "Miami, FL", counterparty_name: "Panama Auto Brokers S.A.",
  counterparty_country: "PA", transacted_at: DateTime.parse("2024-11-26 14:00")
)

# ---------------------------------------------------------------------------
# SCENARIO 8: ROUND-DOLLAR WIRE TRANSFERS – Apex Capital Partners
# Multiple exact $50,000 wires with no business description
# ---------------------------------------------------------------------------
round_dollar_txns = [
  ["TXN-AP-001", "2024-10-01 10:00", "TXN-APEX-REF-0001"],
  ["TXN-AP-002", "2024-10-03 14:00", "TXN-APEX-REF-0002"],
  ["TXN-AP-003", "2024-10-07 09:30", "TXN-APEX-REF-0003"],
  ["TXN-AP-004", "2024-10-10 11:15", "TXN-APEX-REF-0004"],
  ["TXN-AP-005", "2024-10-14 16:00", "TXN-APEX-REF-0005"],
  ["TXN-AP-006", "2024-10-17 10:30", "TXN-APEX-REF-0006"],
  ["TXN-AP-007", "2024-10-21 13:45", "TXN-APEX-REF-0007"],
]

round_dollar_txns.each do |ref, date, memo|
  txns[ref.to_sym] = FinancialTransaction.create!(
    txn_ref: ref, from_account: acc_apex, amount: 50_000.00, currency: "USD",
    txn_type: "wire_transfer", description: memo,
    location: "New York, NY", counterparty_name: "Various offshore recipients",
    counterparty_country: "VG", transacted_at: DateTime.parse(date)
  )
end

# ---------------------------------------------------------------------------
# SCENARIO 9: CRYPTO-TO-FIAT CONVERSION – Dimitri Volkov
# Large USD deposits from crypto exchanges followed by wires abroad
# ---------------------------------------------------------------------------
crypto_txns = [
  ["TXN-DV-001", "2024-08-05 10:00", 45_000.00, "Coinbase Pro – USD withdrawal ref: CB-20240805"],
  ["TXN-DV-002", "2024-08-12 14:30", 38_500.00, "Kraken exchange – fiat withdrawal"],
  ["TXN-DV-003", "2024-08-19 11:15", 52_000.00, "Binance US – BTC liquidation proceeds"],
  ["TXN-DV-004", "2024-08-26 09:45", 41_000.00, "Coinbase – ETH sell order settlement"],
  ["TXN-DV-005", "2024-09-03 13:00", 48_500.00, "Crypto exchange withdrawal – ref: KRK-90311"],
]

crypto_txns.each do |ref, date, amt, desc|
  txns[ref.to_sym] = FinancialTransaction.create!(
    txn_ref: ref, to_account: acc_dimitri, amount: amt, currency: "USD",
    txn_type: "crypto_conversion", description: desc, location: "New York, NY",
    counterparty_name: desc.split("–").first.strip, transacted_at: DateTime.parse(date)
  )
end

txns[:dv_w1] = FinancialTransaction.create!(
  txn_ref: "TXN-DV-006", from_account: acc_dimitri, amount: 120_000.00, currency: "USD",
  txn_type: "wire_transfer", description: "International wire – personal investment",
  location: "New York, NY", counterparty_name: "Baltic Crypto Holdings OÜ",
  counterparty_country: "EE", transacted_at: DateTime.parse("2024-09-10 11:00")
)
txns[:dv_w2] = FinancialTransaction.create!(
  txn_ref: "TXN-DV-007", from_account: acc_dimitri, amount: 80_000.00, currency: "USD",
  txn_type: "wire_transfer", description: "Transfer – offshore account",
  location: "New York, NY", counterparty_name: "Volkov Family Fund",
  counterparty_country: "RU", transacted_at: DateTime.parse("2024-09-15 14:30")
)

# ---------------------------------------------------------------------------
# SCENARIO 10: TRADE-BASED MONEY LAUNDERING – Silk Road Trading Co.
# Import company receives payments 10x declared invoice values
# ---------------------------------------------------------------------------
silk_txns = [
  ["TXN-SR-001", "2024-07-10 09:00", 280_000.00, "Invoice #SR-2024-071 – Electronics shipment", "Fujian Horizon Tech Ltd.", "CN"],
  ["TXN-SR-002", "2024-07-24 11:30", 195_000.00, "Invoice #SR-2024-072 – Consumer goods",        "Guangzhou Star Exports",  "CN"],
  ["TXN-SR-003", "2024-08-08 14:00", 320_000.00, "Invoice #SR-2024-073 – Machinery parts",       "Shanghai Pacific Trade",  "CN"],
  ["TXN-SR-004", "2024-08-22 10:15", 245_000.00, "Invoice #SR-2024-074 – Textiles",              "Beijing Allied Supply",   "CN"],
  ["TXN-SR-005", "2024-09-05 13:45", 310_000.00, "Invoice #SR-2024-075 – Electronics components","Shenzhen Global Traders", "CN"],
]

silk_txns.each do |ref, date, amt, desc, party, country|
  txns[ref.to_sym] = FinancialTransaction.create!(
    txn_ref: ref, to_account: acc_silk, amount: amt, currency: "USD",
    txn_type: "wire_transfer", description: desc, location: "Los Angeles, CA",
    counterparty_name: party, counterparty_country: country,
    transacted_at: DateTime.parse(date)
  )
end

txns[:sr_out] = FinancialTransaction.create!(
  txn_ref: "TXN-SR-006", from_account: acc_silk, amount: 1_100_000.00, currency: "USD",
  txn_type: "wire_transfer", description: "Bulk payment – supplier settlement Q3",
  location: "Los Angeles, CA", counterparty_name: "Sunrise Commodity Group Ltd.",
  counterparty_country: "HK", transacted_at: DateTime.parse("2024-09-20 15:00")
)

puts "Seeding alerts..."

# ---------------------------------------------------------------------------
# ALERTS
# ---------------------------------------------------------------------------

Alert.create!(
  alert_id:      "AML-2024-001",
  alert_type:    "Structured Cash Deposits (Smurfing)",
  severity:      "high",
  status:        "open",
  customer:      carlos,
  account:       acc_carlos,
  description:   "Five cash deposits totaling $48,550 made in 14-day period, each deliberately below the $10,000 CTR reporting threshold. Pattern is consistent with structuring under 31 U.S.C. § 5324.",
  rule_triggered: "Rule AML-102: Multiple Sub-Threshold Cash Deposits",
  txn_refs:      %w[TXN-CM-001 TXN-CM-002 TXN-CM-003 TXN-CM-004 TXN-CM-005],
  metadata: {
    total_amount:       48_550.00,
    avg_transaction:    9_710.00,
    threshold_avoidance_margin: "$100–$500 below CTR threshold",
    pattern:            "Structuring",
    risk_indicators:    ["Sub-threshold deposits", "Consistent pattern over 14 days", "Import/Export occupation (high cash exposure risk)"]
  }
)

Alert.create!(
  alert_id:      "AML-2024-002",
  alert_type:    "Rapid Fund Movement / Pass-Through Layering",
  severity:      "critical",
  status:        "open",
  customer:      bright,
  account:       acc_bright,
  description:   "Bright Future LLC received a $500,000 international wire from Cayman Islands entity. Within 48 hours, $455,000 was distributed to five separate accounts in sub-$100K tranches with minimal business justification. Classic funnel-and-distribute layering pattern.",
  rule_triggered: "Rule AML-215: Rapid Outflow Following Large Inbound Wire",
  txn_refs:      %w[TXN-BF-001 TXN-BF-002 TXN-BF-003 TXN-BF-004 TXN-BF-005 TXN-BF-006],
  metadata: {
    inbound_amount:  500_000.00,
    outbound_amount: 455_000.00,
    time_to_distribute: "48 hours",
    recipients:      5,
    originator_jurisdiction: "Cayman Islands (FATF monitored)",
    risk_indicators: ["Offshore wire origin", "Rapid re-distribution", "Investment holding company with limited disclosed business", "Cayman Islands jurisdiction"]
  }
)

Alert.create!(
  alert_id:      "AML-2024-003",
  alert_type:    "PEP Suspicious Wire Transfer",
  severity:      "critical",
  status:        "open",
  customer:      emmanuel,
  account:       acc_emmanuel,
  description:   "Retired Nigerian government minister received $450,000 wire from Cyprus-registered advisory firm with no established business relationship. Funds were rapidly redistributed to a Swiss trust and via cash withdrawal. PEP status requires enhanced scrutiny.",
  rule_triggered: "Rule AML-310: PEP Large Inbound Wire",
  txn_refs:      %w[TXN-EO-001 TXN-EO-002 TXN-EO-003 TXN-EO-004],
  metadata: {
    pep_status:      true,
    originator_jurisdiction: "Cyprus (offshore financial center)",
    unexplained_wealth: true,
    rapid_redistribution: true,
    risk_indicators: ["Politically Exposed Person", "Enhanced Due Diligence required", "Offshore wire origin (Cyprus)", "Rapid redistribution to Swiss trust", "Large cash withdrawal post-receipt"]
  }
)

Alert.create!(
  alert_id:      "AML-2024-004",
  alert_type:    "Funnel Account Activity",
  severity:      "high",
  status:        "open",
  customer:      marcus,
  account:       acc_marcus,
  description:   "Marcus Williams received 12 ACH transfers totaling $24,500 from unrelated parties over 12 days, then withdrew $26,500 in cash the following day. Income level and account history are inconsistent with this volume. Account appears to be used as a collection point.",
  rule_triggered: "Rule AML-118: Funnel Account – Multiple Inbound / Single Outbound",
  txn_refs:      %w[TXN-MW-001 TXN-MW-002 TXN-MW-003 TXN-MW-004 TXN-MW-005 TXN-MW-006 TXN-MW-007 TXN-MW-008 TXN-MW-009 TXN-MW-010 TXN-MW-011 TXN-MW-012 TXN-MW-013],
  metadata: {
    inbound_total:   24_500.00,
    cash_withdrawal: 26_500.00,
    sender_count:    12,
    occupation_income_mismatch: true,
    risk_indicators: ["Multiple unrelated senders", "Large cash withdrawal", "Income inconsistent with activity volume", "All deposits within 12-day window"]
  }
)

Alert.create!(
  alert_id:      "AML-2024-005",
  alert_type:    "Dormant Account Sudden Activation",
  severity:      "high",
  status:        "open",
  customer:      sarah,
  account:       acc_sarah,
  description:   "Savings account with no activity for 3+ years suddenly received a $220,000 international wire from a Hong Kong law firm. Within 5 days, $150,000 was redistributed via wire and cash withdrawal. Account holder is a 79-year-old retired teacher.",
  rule_triggered: "Rule AML-205: Dormant Account Large Inbound Wire",
  txn_refs:      %w[TXN-SC-001 TXN-SC-002 TXN-SC-003],
  metadata: {
    dormant_period:  "3+ years",
    inbound_amount:  220_000.00,
    redistribution:  150_000.00,
    originator_jurisdiction: "Hong Kong",
    risk_indicators: ["Account dormant 3+ years", "Sudden large wire deposit", "Rapid redistribution", "Elderly account holder – potential elder financial exploitation"]
  }
)

Alert.create!(
  alert_id:      "AML-2024-006",
  alert_type:    "Unusual Cash Deposit Volume – Cash-Intensive Business",
  severity:      "high",
  status:        "open",
  customer:      golden,
  account:       acc_golden,
  description:   "Golden Dragon Restaurant Group has been making weekly cash deposits of $52,000–$63,500 over the past 6 weeks, totaling $349,100. Historical baseline for this account was $5,000–$8,000 per week. No business event or seasonal factor explains a 700% increase.",
  rule_triggered: "Rule AML-130: Cash Deposit Volume Spike – Business Account",
  txn_refs:      %w[TXN-GD-001 TXN-GD-002 TXN-GD-003 TXN-GD-004 TXN-GD-005 TXN-GD-006],
  metadata: {
    total_deposits:    349_100.00,
    avg_weekly_current: 58_183.00,
    avg_weekly_historical: 6_500.00,
    volume_increase:   "795%",
    risk_indicators:   ["Cash deposit volume 795% above historical baseline", "No disclosed business event", "Restaurant revenue inconsistent with deposit volume"]
  }
)

Alert.create!(
  alert_id:      "AML-2024-007",
  alert_type:    "Coordinated Smurfing – Multiple Structured Deposits",
  severity:      "high",
  status:        "open",
  customer:      victor,
  account:       acc_victor,
  description:   "Three individuals (Diego Ramirez, Ana Torres, Luis Vargas) made coordinated same-day cash deposits of $8,700–$9,400 into Victor Salinas's account on two separate occasions. Total received: $54,100, immediately wired to a Panamanian company. All three senders are Colombian/Mexican nationals with low income profiles.",
  rule_triggered: "Rule AML-145: Coordinated Multi-Party Structured Deposits",
  txn_refs:      %w[TXN-SM-001 TXN-SM-002 TXN-SM-003 TXN-SM-004 TXN-SM-005 TXN-SM-006 TXN-SM-007],
  metadata: {
    total_deposited: 54_100.00,
    number_of_smurfs: 3,
    recipient_wire:  "Panama – Auto Brokers",
    same_day_coordination: true,
    risk_indicators:   ["Coordinated same-day deposits", "All deposits below CTR threshold", "Immediate offshore wire after collection", "Senders' income inconsistent with amounts"]
  }
)

Alert.create!(
  alert_id:      "AML-2024-008",
  alert_type:    "Round-Dollar Wire Transfers – Threshold Patterning",
  severity:      "medium",
  status:        "open",
  customer:      apex,
  account:       acc_apex,
  description:   "Apex Capital Partners executed 7 outbound wire transfers of exactly $50,000 each over a 21-day period to British Virgin Islands entities, with no business justification or invoice references. Round-dollar amounts to high-risk jurisdiction suggest structuring or placement activity.",
  rule_triggered: "Rule AML-220: Round-Dollar Wire Pattern – Offshore Jurisdiction",
  txn_refs:      %w[TXN-AP-001 TXN-AP-002 TXN-AP-003 TXN-AP-004 TXN-AP-005 TXN-AP-006 TXN-AP-007],
  metadata: {
    total_wired:     350_000.00,
    per_wire:        50_000.00,
    wire_count:      7,
    destination:     "British Virgin Islands",
    round_dollar:    true,
    risk_indicators: ["Exact round-dollar amounts", "High-risk offshore jurisdiction (BVI)", "No business documentation", "Consistent 3-4 day interval between wires"]
  }
)

Alert.create!(
  alert_id:      "AML-2024-009",
  alert_type:    "Crypto-to-Fiat Conversion with Offshore Layering",
  severity:      "high",
  status:        "open",
  customer:      dimitri,
  account:       acc_dimitri,
  description:   "Dimitri Volkov (Russian national, EDD) received 5 large crypto exchange cash-out deposits totaling $225,000 over 29 days. Within 2 weeks, $200,000 was wired offshore: $120,000 to an Estonian crypto holding company and $80,000 to a Russian family fund. Pattern consistent with crypto layering.",
  rule_triggered: "Rule AML-315: Crypto Conversion with Rapid Offshore Transfer",
  txn_refs:      %w[TXN-DV-001 TXN-DV-002 TXN-DV-003 TXN-DV-004 TXN-DV-005 TXN-DV-006 TXN-DV-007],
  metadata: {
    crypto_inflows:  225_000.00,
    offshore_outflows: 200_000.00,
    days_to_repatriate: 14,
    destination_countries: ["Estonia", "Russia"],
    subject_nationality: "Russian Federation",
    risk_indicators:   ["High-risk nationality (Russia – OFAC monitored)", "Enhanced Due Diligence required", "Crypto-to-fiat pattern", "Rapid offshore layering after conversion", "Dual offshore destinations"]
  }
)

Alert.create!(
  alert_id:      "AML-2024-010",
  alert_type:    "Trade-Based Money Laundering (TBML)",
  severity:      "critical",
  status:        "open",
  customer:      silk,
  account:       acc_silk,
  description:   "Silk Road Trading Co. received $1,350,000 in wire payments from five Chinese entities over 10 weeks, purportedly for electronics and goods shipments. Declared import values on customs forms total only $138,000 – an over-invoicing ratio of approximately 10:1. Funds were then bulk-wired to Hong Kong. Classic TBML pattern.",
  rule_triggered: "Rule AML-420: Trade Invoice Value Discrepancy – TBML Indicator",
  txn_refs:      %w[TXN-SR-001 TXN-SR-002 TXN-SR-003 TXN-SR-004 TXN-SR-005 TXN-SR-006],
  metadata: {
    wire_payments_received: 1_350_000.00,
    declared_customs_value:   138_000.00,
    over_invoice_ratio:       "9.8:1",
    destination_after_receipt: "Hong Kong",
    origin_country:           "China",
    risk_indicators:          ["Over-invoicing 10x declared value", "EDD customer", "Bulk offshore wire after receipt", "High-risk jurisdiction (China-origin, HK destination)", "Trade document inconsistency"]
  }
)

puts ""
puts "========================================"
puts "Seed data loaded successfully!"
puts "  Customers:    #{Customer.count}"
puts "  Accounts:     #{Account.count}"
puts "  Transactions: #{FinancialTransaction.count}"
puts "  Alerts:       #{Alert.count}"
puts "========================================"
