# AlertDetectionService
#
# Scans Account + FinancialTransaction data using deterministic AML rules.
# No AI involved — purely rule-based detection.
#
# ── Rules implemented ────────────────────────────────────────────────
#   HIGH_FREQUENCY    – Too many transactions in rolling 24h window
#   LARGE_AMOUNT      – Large single OR cumulative outbound transactions
#   STRUCTURING       – Multiple transactions just below reporting threshold
#   UNUSUAL_GEOGRAPHY – High-risk countries or too many countries
#   DORMANT_ACTIVITY  – Dormant account with significant activity
#
# ── Incremental scanning ─────────────────────────────────────────────
#   Uses `last_detected_at` per account.
#   Only accounts with NEW transactions are scanned.
#   Prevents re-processing historical data.
#
class AlertDetectionService
  HIGH_RISK_COUNTRIES = %w[IR KP SY CU AF MM SD LY SO YE].freeze

  # ── Rule thresholds ────────────────────────────────────────────────
  FREQ_WINDOW_HOURS     = 24
  FREQ_MEDIUM_THRESHOLD = 5
  FREQ_HIGH_THRESHOLD   = 10

  LARGE_SINGLE_THRESHOLD     = 10_000
  LARGE_CUMULATIVE_THRESHOLD = 50_000
  LARGE_CRITICAL_THRESHOLD   = 200_000

  STRUCTURING_MIN            = 3
  STRUCTURING_RANGE          = 8_000..9_999

  GEO_WINDOW_DAYS   = 7
  GEO_MIN_COUNTRIES = 3

  DORMANT_LOOKBACK_DAYS = 90

  DUPLICATE_WINDOW = 24.hours

  def self.run(account_ids: nil, force_full_scan: false)
    new(account_ids: account_ids, force_full_scan: force_full_scan).run
  end

  def initialize(account_ids:, force_full_scan:)
    @account_ids     = account_ids
    @force_full_scan = force_full_scan
    @created         = []
    @skipped         = []
    @accounts_scanned = 0
  end

  def run
    run_started_at = Time.current

    accounts_scope.find_each do |account|
      @accounts_scanned += 1
      new_since = account.last_detected_at

      detect_high_frequency(account, new_since:)
      detect_large_amounts(account, new_since:)
      detect_structuring(account, new_since:)
      detect_unusual_geography(account, new_since:)
      detect_dormant_activity(account, new_since:)

      # Safe update (prevents missing mid-run transactions)
      account.update_column(:last_detected_at, run_started_at)
    end

    log_summary

    {
      created: @created,
      skipped: @skipped,
      accounts_scanned: @accounts_scanned
    }
  end

  private

  # ── Incremental scope ──────────────────────────────────────────────
  def accounts_scope
    scope = Account.includes(:customer)
    scope = scope.where(id: @account_ids) if @account_ids.present?
    scope = apply_incremental_filter(scope) unless @force_full_scan
    scope
  end

  def apply_incremental_filter(scope)
    scope.where(
      "accounts.last_detected_at IS NULL OR EXISTS (
        SELECT 1 FROM financial_transactions ft
        WHERE (ft.from_account_id = accounts.id OR ft.to_account_id = accounts.id)
        AND ft.status = 'completed'
        AND ft.transacted_at > accounts.last_detected_at
      )"
    )
  end

  # ── Transaction helpers ────────────────────────────────────────────
  def all_txns(account, since:)
    scope = FinancialTransaction
              .where(status: "completed")
              .where("from_account_id = :id OR to_account_id = :id", id: account.id)
    scope = scope.where("transacted_at >= ?", since) if since
    scope.load
  end

  def outbound_txns(account, since:)
    scope = FinancialTransaction
              .where(status: "completed", from_account_id: account.id)
    scope = scope.where("transacted_at >= ?", since) if since
    scope.load
  end

  # ── Rule 1: Frequency ──────────────────────────────────────────────
  def detect_high_frequency(account, new_since:)
    rule = "HIGH_FREQUENCY"
    since = [new_since, FREQ_WINDOW_HOURS.hours.ago].compact.max

    txns = all_txns(account, since:)
    count = txns.size

    return if count < FREQ_MEDIUM_THRESHOLD
    return if duplicate_open_alert?(account, rule)

    severity = count >= FREQ_HIGH_THRESHOLD ? "high" : "medium"

    create_alert!(
      account:, rule:, severity:, txns:,
      alert_type: "High Transaction Frequency",
      description: "Detected #{count} transactions in #{FREQ_WINDOW_HOURS}h window",
      metadata: { count: count }
    )
  end

  # ── Rule 2: Large Amount ───────────────────────────────────────────
  def detect_large_amounts(account, new_since:)
    rule = "LARGE_AMOUNT"

    new_txns = outbound_txns(account, since: new_since)
    return if new_txns.empty?

    large_txns = new_txns.select { |t| t.amount >= LARGE_SINGLE_THRESHOLD }

    cumulative = outbound_txns(account, since: 30.days.ago).sum(&:amount)

    return if large_txns.empty? && cumulative < LARGE_CUMULATIVE_THRESHOLD
    return if duplicate_open_alert?(account, rule)

    severity =
      if cumulative >= LARGE_CRITICAL_THRESHOLD then "critical"
      elsif cumulative >= LARGE_CUMULATIVE_THRESHOLD then "high"
      else "medium"
      end

    create_alert!(
      account:, rule:, severity:, txns: large_txns,
      alert_type: "Large Transaction",
      description: "Large or cumulative transactions detected",
      metadata: { cumulative: cumulative }
    )
  end

  # ── Rule 3: Structuring ────────────────────────────────────────────
  def detect_structuring(account, new_since:)
    rule = "STRUCTURING"

    txns = outbound_txns(account, since: new_since)
             .select { |t| STRUCTURING_RANGE.cover?(t.amount) }

    return if txns.size < STRUCTURING_MIN
    return if duplicate_open_alert?(account, rule)

    create_alert!(
      account:, rule:, severity: "high", txns: txns,
      alert_type: "Structuring",
      description: "Multiple transactions just below threshold detected",
      metadata: { count: txns.size }
    )
  end

  # ── Rule 4: Geography ──────────────────────────────────────────────
  def detect_unusual_geography(account, new_since:)
    rule = "UNUSUAL_GEOGRAPHY"

    recent_txns = all_txns(account, since: GEO_WINDOW_DAYS.days.ago)
    new_txns    = all_txns(account, since: [new_since, GEO_WINDOW_DAYS.days.ago].compact.max)

    countries = recent_txns.map(&:counterparty_country).compact.uniq
    new_high_risk = new_txns.select { |t| HIGH_RISK_COUNTRIES.include?(t.counterparty_country) }

    return if new_high_risk.empty? && countries.size < GEO_MIN_COUNTRIES
    return if duplicate_open_alert?(account, rule)

    severity = new_high_risk.any? ? "high" : "medium"

    create_alert!(
      account:, rule:, severity:, txns: new_txns,
      alert_type: "Geographic Risk",
      description: "Suspicious country activity detected",
      metadata: { countries: countries }
    )
  end

  # ── Rule 5: Dormant ────────────────────────────────────────────────
  def detect_dormant_activity(account, new_since:)
    return unless account.status == "dormant"

    rule = "DORMANT_ACTIVITY"
    txns = all_txns(account, since: new_since || DORMANT_LOOKBACK_DAYS.days.ago)

    significant = txns.select { |t| t.amount >= LARGE_SINGLE_THRESHOLD }

    return if significant.empty?
    return if duplicate_open_alert?(account, rule)

    create_alert!(
      account:, rule:, severity: "high", txns: significant,
      alert_type: "Dormant Activity",
      description: "Dormant account shows significant activity",
      metadata: { txn_count: significant.size }
    )
  end

  # ── Alert helpers ──────────────────────────────────────────────────
  def create_alert!(account:, rule:, severity:, txns:, alert_type:, description:, metadata:)
    alert = Alert.create!(
      alert_id: generate_alert_id(rule),
      alert_type: alert_type,
      severity: severity,
      status: "open",
      customer: account.customer,
      account: account,
      description: description,
      rule_triggered: rule,
      txn_refs: txns.map(&:txn_ref),
      metadata: metadata
    )

    @created << { account: account.account_number, rule: rule, severity: severity }
    alert
  end

  def duplicate_open_alert?(account, rule)
    Alert.where(account_id: account.id, rule_triggered: rule, status: "open")
         .where("created_at > ?", DUPLICATE_WINDOW.ago)
         .exists?
  end

  def generate_alert_id(rule)
    "ALT-#{rule}-#{SecureRandom.hex(4)}"
  end

  def log_summary
    Rails.logger.info("AML scan complete: #{@accounts_scanned} accounts, #{@created.size} alerts")
  end
end