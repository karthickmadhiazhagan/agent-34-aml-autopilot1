class Alert < ApplicationRecord
  belongs_to :customer
  belongs_to :account

  SEVERITY_ORDER = { "critical" => 4, "high" => 3, "medium" => 2, "low" => 1 }.freeze

  def transactions
    refs = txn_refs || []
    FinancialTransaction.where(txn_ref: refs).order(:transacted_at)
  end

  # Builds the full alert data hash used by the AI investigation pipeline.
  # This replaces DummyAlertService.find(id) throughout the app.
  def as_alert_data
    txns = transactions
    total_amount = txns.sum { |t| t.amount.to_f }
    dates = txns.map(&:transacted_at).compact.sort

    {
      alert_id:   alert_id,
      alert_type: alert_type,
      severity:   severity.upcase,
      status:     status.upcase,
      customer:   customer.as_json_data,
      account:    account.as_json_data,
      transactions: txns.map(&:as_json_data),
      flagged_transactions: txns.map(&:as_json_data),   # all are flagged by default
      metadata: (metadata || {}).merge(
        total_amount:      total_amount.round(2),
        transaction_count: txns.size,
        time_period:       dates.any? ? "#{dates.first.strftime('%Y-%m-%d')} to #{dates.last.strftime('%Y-%m-%d')}" : "N/A",
        rule_triggered:    rule_triggered,
        risk_indicators:   build_risk_indicators
      )
    }
  end

  # Compact summary for the alerts list page
  def as_summary
    txns  = transactions
    total = txns.sum { |t| t.amount.to_f }

    {
      alert_id:          alert_id,
      alert_type:        alert_type,
      severity:          severity.upcase,
      status:            status.upcase,
      customer:          { id: customer.customer_id, name: customer.name, risk_score: customer.risk_score },
      account:           { account_number: account.account_number, type: account.account_type },
      description:       description,
      total_amount:      total.round(2),
      transaction_count: txns.size,
      created_at:        created_at
    }
  end

  private

  def build_risk_indicators
    indicators = []
    indicators << "Politically Exposed Person (PEP)" if customer.is_pep
    indicators << "Enhanced Due Diligence required"  if customer.kyc_status == "enhanced_due_diligence"
    indicators << "High risk score (#{customer.risk_score}/100)" if customer.risk_score >= 70
    indicators << "High-risk nationality (#{customer.nationality})" if %w[RU IR KP SY CU].include?(customer.nationality)
    indicators << "Dormant account" if account.status == "dormant"
    indicators << "Frozen account" if account.status == "frozen"
    indicators << (metadata || {})["risk_indicators"] || []
    indicators.flatten.compact.uniq
  end
end
