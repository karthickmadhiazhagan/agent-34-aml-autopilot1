# DummyAlertService – Simulates an AML monitoring system API.
# Returns realistic alert data without requiring an external connection.
class DummyAlertService
  ALERTS = {
    "ALERT_1001" => {
      alert_id: "ALERT_1001",
      alert_type: "Unusual Wire Activity",
      alert_generated_date: "2025-02-01",
      severity: "High",
      customer_profile: {
        customer_id: "CUST_78901",
        customer_name: "ABC Retail Traders",
        business_type: "Retail Merchandise Sales",
        account_open_date: "2022-06-15",
        expected_monthly_turnover: 250_000,
        risk_rating: "Medium"
      },
      kyc: {
        id_verified: true,
        beneficial_owner_disclosed: true,
        last_kyc_review: "2024-08-10",
        pep_status: false,
        sanctions_match: false
      },
      transactions: [
        { txn_id: "TXN_A001", date: "2025-01-20", type: "Wire In",  amount: 180_000, originator: "Rapid Cargo LLC",      country: "UAE" },
        { txn_id: "TXN_A002", date: "2025-01-20", type: "Wire In",  amount: 95_000,  originator: "Prime Trade Solutions", country: "HK" },
        { txn_id: "TXN_A003", date: "2025-01-21", type: "Wire Out", amount: 260_000, beneficiary: "Offshore Holdings Ltd", country: "BVI" },
        { txn_id: "TXN_A004", date: "2025-01-22", type: "Wire In",  amount: 120_000, originator: "Global Freight Inc",    country: "SG" },
        { txn_id: "TXN_A005", date: "2025-01-22", type: "Wire Out", amount: 118_000, beneficiary: "Shell Commerce LLC",    country: "PAN" }
      ],
      total_inbound: 395_000,
      total_outbound: 378_000,
      prior_sars: []
    },

    "ALERT_1002" => {
      alert_id: "ALERT_1002",
      alert_type: "Structuring / Smurfing",
      alert_generated_date: "2025-02-05",
      severity: "High",
      customer_profile: {
        customer_id: "CUST_11234",
        customer_name: "John M. Smith",
        business_type: "Individual",
        account_open_date: "2020-03-10",
        expected_monthly_turnover: 8_000,
        risk_rating: "Low"
      },
      kyc: {
        id_verified: true,
        beneficial_owner_disclosed: true,
        last_kyc_review: "2023-03-10",
        pep_status: false,
        sanctions_match: false
      },
      transactions: [
        { txn_id: "TXN_B001", date: "2025-01-28", type: "Cash Deposit", amount: 9_800,  branch: "Downtown" },
        { txn_id: "TXN_B002", date: "2025-01-28", type: "Cash Deposit", amount: 9_500,  branch: "Eastside" },
        { txn_id: "TXN_B003", date: "2025-01-29", type: "Cash Deposit", amount: 9_700,  branch: "Northgate" },
        { txn_id: "TXN_B004", date: "2025-01-30", type: "Cash Deposit", amount: 9_200,  branch: "Westpark" },
        { txn_id: "TXN_B005", date: "2025-01-30", type: "Wire Out",     amount: 37_000, beneficiary: "Anon Holding Corp", country: "CYP" }
      ],
      total_inbound: 38_200,
      total_outbound: 37_000,
      prior_sars: [{ sar_id: "SAR_2023_4421", filed_date: "2023-09-15", reason: "Unusual cash activity" }]
    },

    "ALERT_1003" => {
      alert_id: "ALERT_1003",
      alert_type: "High-Volume Cash Deposits",
      alert_generated_date: "2025-02-10",
      severity: "Medium",
      customer_profile: {
        customer_id: "CUST_55678",
        customer_name: "Maria E. Garcia",
        business_type: "Restaurant Owner",
        account_open_date: "2019-11-20",
        expected_monthly_turnover: 40_000,
        risk_rating: "Low"
      },
      kyc: {
        id_verified: true,
        beneficial_owner_disclosed: true,
        last_kyc_review: "2024-11-20",
        pep_status: false,
        sanctions_match: false
      },
      transactions: [
        { txn_id: "TXN_C001", date: "2025-01-10", type: "Cash Deposit", amount: 18_000, branch: "Main Street" },
        { txn_id: "TXN_C002", date: "2025-01-15", type: "Cash Deposit", amount: 22_000, branch: "Main Street" },
        { txn_id: "TXN_C003", date: "2025-01-20", type: "Cash Deposit", amount: 25_000, branch: "Airport" },
        { txn_id: "TXN_C004", date: "2025-01-25", type: "Cash Deposit", amount: 19_500, branch: "Main Street" },
        { txn_id: "TXN_C005", date: "2025-01-31", type: "Wire Out",     amount: 80_000, beneficiary: "Family Trust Account", country: "MX" }
      ],
      total_inbound: 84_500,
      total_outbound: 80_000,
      prior_sars: []
    },

    "ALERT_1004" => {
      alert_id: "ALERT_1004",
      alert_type: "Rapid Pass-Through / Funnel Account",
      alert_generated_date: "2025-02-15",
      severity: "Critical",
      customer_profile: {
        customer_id: "CUST_33456",
        customer_name: "XYZ Import Export LLC",
        business_type: "Import/Export Trade",
        account_open_date: "2023-01-08",
        expected_monthly_turnover: 500_000,
        risk_rating: "High"
      },
      kyc: {
        id_verified: true,
        beneficial_owner_disclosed: false,
        last_kyc_review: "2024-01-08",
        pep_status: true,
        sanctions_match: false
      },
      transactions: [
        { txn_id: "TXN_D001", date: "2025-02-01", type: "Wire In",  amount: 200_000, originator: "Vendor Alpha LLC",    country: "CN" },
        { txn_id: "TXN_D002", date: "2025-02-01", type: "Wire In",  amount: 150_000, originator: "Vendor Beta Corp",    country: "RU" },
        { txn_id: "TXN_D003", date: "2025-02-01", type: "Wire In",  amount: 180_000, originator: "Vendor Gamma Inc",    country: "UA" },
        { txn_id: "TXN_D004", date: "2025-02-02", type: "Wire Out", amount: 490_000, beneficiary: "Cayman Holdings Ltd", country: "CYM" },
        { txn_id: "TXN_D005", date: "2025-02-03", type: "Wire In",  amount: 310_000, originator: "Vendor Delta LLC",    country: "CN" },
        { txn_id: "TXN_D006", date: "2025-02-03", type: "Wire Out", amount: 305_000, beneficiary: "BVI Finance Group",  country: "BVI" }
      ],
      total_inbound: 840_000,
      total_outbound: 795_000,
      prior_sars: [{ sar_id: "SAR_2024_0089", filed_date: "2024-06-20", reason: "Rapid fund movement" }]
    },

    "ALERT_1005" => {
      alert_id: "ALERT_1005",
      alert_type: "Multiple Account Transfers",
      alert_generated_date: "2025-02-20",
      severity: "Medium",
      customer_profile: {
        customer_id: "CUST_99012",
        customer_name: "Tech Solutions LLC",
        business_type: "IT Consulting",
        account_open_date: "2021-07-15",
        expected_monthly_turnover: 120_000,
        risk_rating: "Medium"
      },
      kyc: {
        id_verified: true,
        beneficial_owner_disclosed: true,
        last_kyc_review: "2024-07-15",
        pep_status: false,
        sanctions_match: false
      },
      transactions: [
        { txn_id: "TXN_E001", date: "2025-02-05", type: "Wire In",    amount: 95_000,  originator: "Client A Corp",   country: "US" },
        { txn_id: "TXN_E002", date: "2025-02-06", type: "Internal Transfer", amount: 40_000, to_account: "ACC_9901" },
        { txn_id: "TXN_E003", date: "2025-02-06", type: "Internal Transfer", amount: 40_000, to_account: "ACC_9902" },
        { txn_id: "TXN_E004", date: "2025-02-07", type: "Wire Out",   amount: 38_000,  beneficiary: "Consulting Fees Offshore", country: "MU" },
        { txn_id: "TXN_E005", date: "2025-02-07", type: "Wire Out",   amount: 37_500,  beneficiary: "Tech Vendor PTE",          country: "SG" },
        { txn_id: "TXN_E006", date: "2025-02-10", type: "Wire In",    amount: 130_000, originator: "Client B International", country: "GB" },
        { txn_id: "TXN_E007", date: "2025-02-10", type: "Wire Out",   amount: 128_000, beneficiary: "Layered Corp Ltd",       country: "PA" }
      ],
      total_inbound: 225_000,
      total_outbound: 203_500,
      prior_sars: []
    }
  }.freeze

  def self.all_alerts
    ALERTS.values.map { |a| summary(a) }
  end

  def self.find(alert_id)
    ALERTS[alert_id.to_s.upcase]
  end

  private_class_method def self.summary(alert)
    {
      alert_id:             alert[:alert_id],
      alert_type:           alert[:alert_type],
      alert_generated_date: alert[:alert_generated_date],
      severity:             alert[:severity],
      customer_name:        alert.dig(:customer_profile, :customer_name),
      risk_rating:          alert.dig(:customer_profile, :risk_rating),
      total_inbound:        alert[:total_inbound],
      total_outbound:       alert[:total_outbound]
    }
  end
end
