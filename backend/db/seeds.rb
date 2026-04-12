# =============================================================================
# AML Autopilot – FULL Seed Data (50+ Customers)
# =============================================================================

puts "Clearing existing data..."
Alert.delete_all
FinancialTransaction.delete_all
Account.delete_all
Customer.delete_all

# =============================================================================
# HELPERS
# =============================================================================

def safe_location(from, to)
  (from || to)&.branch || "Unknown"
end

def d(days)
  days.days.ago
end

wire = ->(ref, from, to, amt, date, desc, party = nil, country = "US") {
  FinancialTransaction.create!(
    txn_ref: ref,
    from_account: from,
    to_account: to,
    amount: amt,
    currency: "USD",
    txn_type: "wire_transfer",
    description: desc,
    counterparty_name: party,
    counterparty_country: country,
    location: safe_location(from, to),
    status: "completed",
    transacted_at: date
  )
}

deposit = ->(ref, acct, amt, date, desc) {
  FinancialTransaction.create!(
    txn_ref: ref,
    to_account: acct,
    amount: amt,
    currency: "USD",
    txn_type: "cash_deposit",
    description: desc,
    counterparty_name: "Cash Teller",
    counterparty_country: "US",
    location: acct.branch || "Unknown",
    status: "completed",
    transacted_at: date
  )
}

ach = ->(ref, from, to, amt, date, desc, party = nil) {
  FinancialTransaction.create!(
    txn_ref: ref,
    from_account: from,
    to_account: to,
    amount: amt,
    currency: "USD",
    txn_type: "ach_transfer",
    description: desc,
    counterparty_name: party,
    counterparty_country: "US",
    location: safe_location(from, to),
    status: "completed",
    transacted_at: date
  )
}

# =============================================================================
# AML CUSTOMERS (Trigger rules)
# =============================================================================

puts "Seeding AML customers..."

carlos   = Customer.create!(customer_id: "CUST_001", name: "Carlos Mendez", risk_score: 78, kyc_status: "verified")
emmanuel = Customer.create!(customer_id: "CUST_002", name: "Emmanuel Okafor", risk_score: 92, kyc_status: "enhanced_due_diligence", is_pep: true)
sarah    = Customer.create!(customer_id: "CUST_003", name: "Sarah Chen", risk_score: 40, kyc_status: "verified")
bright   = Customer.create!(customer_id: "CUST_004", name: "Bright Future LLC", risk_score: 85, kyc_status: "verified")
omar     = Customer.create!(customer_id: "CUST_005", name: "Omar Trade LLC", risk_score: 87, kyc_status: "enhanced_due_diligence")

acc_carlos   = Account.create!(customer: carlos, account_number: "ACC-001", branch: "Miami", status: "active")
acc_emmanuel = Account.create!(customer: emmanuel, account_number: "ACC-002", branch: "NYC", status: "active")
acc_sarah    = Account.create!(customer: sarah, account_number: "ACC-003", branch: "Boston", status: "dormant")
acc_bright   = Account.create!(customer: bright, account_number: "ACC-004", branch: "NYC", status: "active")
acc_omar     = Account.create!(customer: omar, account_number: "ACC-005", branch: "LA", status: "active")

puts "Seeding AML transactions..."

# STRUCTURING
[5,4,3].each_with_index do |day, i|
  deposit.("TXN-CM-#{i}", acc_carlos, 9_500 + i*100, d(day), "Structured deposit")
end
wire.("TXN-CM-OUT", acc_carlos, nil, 30_000, d(2), "Outbound")

# LARGE + PEP
wire.("TXN-EO-IN", nil, acc_emmanuel, 200_000, d(3), "Offshore", "Cyprus Bank", "CY")
wire.("TXN-EO-OUT", acc_emmanuel, nil, 150_000, d(1), "Redistribution")

# DORMANT
wire.("TXN-SC-IN", nil, acc_sarah, 120_000, d(4), "Dormant activity")

# LAYERING
wire.("TXN-BF-IN", nil, acc_bright, 300_000, d(2), "Inbound")
wire.("TXN-BF-OUT1", acc_bright, nil, 120_000, d(1), "Split")
wire.("TXN-BF-OUT2", acc_bright, nil, 100_000, d(1), "Split")

# GEO
wire.("TXN-OM-1", nil, acc_omar, 80_000, d(3), "Iran", "Tehran Co", "IR")
wire.("TXN-OM-2", acc_omar, nil, 60_000, d(2), "Syria", "Damascus Co", "SY")

# =============================================================================
# CLEAN CUSTOMERS (50 AUTO GENERATED)
# =============================================================================

puts "Seeding 50 clean customers..."

50.times do |i|
  customer = Customer.create!(
    customer_id: "CUST_AUTO_#{i}",
    name: "User #{i}",
    email: "user#{i}@test.com",
    risk_score: rand(1..15),
    kyc_status: "verified"
  )

  account = Account.create!(
    customer: customer,
    account_number: "AUTO-ACC-#{i}",
    branch: ["NY", "LA", "Chicago", "Austin"].sample,
    status: "active"
  )

  # salary
  3.times do |j|
    ach.("SAL-#{i}-#{j}", nil, account, rand(2000..5000), d(rand(1..20)), "Salary", "Employer Inc")
  end

  # expenses
  3.times do |j|
    ach.("EXP-#{i}-#{j}", account, nil, rand(100..1500), d(rand(1..20)), "Expense", "Utility")
  end
end

# =============================================================================
# RESET DETECTION
# =============================================================================

puts "Resetting detection markers..."
Account.update_all(last_detected_at: nil)

puts "Done!"
puts "Customers: #{Customer.count}"
puts "Accounts: #{Account.count}"
puts "Transactions: #{FinancialTransaction.count}"