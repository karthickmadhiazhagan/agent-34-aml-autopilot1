# AlertDetectionService
#
# Scans Account + FinancialTransaction data using pure SQL rules.
# Zero AI involvement — no token cost, no external API calls.
# AI is only invoked later, per-alert, when a human starts an Investigation.
#
# ── Four detection rules ────────────────────────────────────────────────
#   HIGH_FREQUENCY    – Too many transactions in a rolling 24-hour window
#   LARGE_AMOUNT      – Single or cumulative outbound exceeds CTR thresholds
#   UNUSUAL_GEOGRAPHY – Counterparties in high-risk or many different countries
#   DORMANT_ACTIVITY  – Dormant-status account shows recent transaction activity
#
# ── Incremental scanning ────────────────────────────────────────────────
#   Each account stores `last_detected_at`. On every run only accounts that
#   have transactions NEWER than that timestamp are re-scanned. Accounts with
#   no new activity are skipped entirely, keeping cost O(active accounts) not
#   O(all accounts).
#   After a successful scan the account's `last_detected_at` is updated so the
#   next run only picks up further new activity.
#
# ── Usage ───────────────────────────────────────────────────────────────
#   AlertDetectionService.run                            # all accounts (incremental)
#   AlertDetectionService.run(account_ids: [1, 2, 3])   # specific accounts
#   AlertDetectionService.run(force_full_scan: true)    # ignore last_detected_at
#
class AlertDetectionService
  # FATF / FinCEN high-risk jurisdictions
  HIGH_RISK_COUNTRIES = %w[IR KP SY CU AF MM SD LY SO YE].freeze

  # ── Rule 1: High Transaction Frequency ──────────────────────────────
  FREQ_WINDOW_HOURS     = 24
  FREQ_MEDIUM_THRESHOLD = 5    # ≥ 5 txns in window → medium
  FREQ_HIGH_THRESHOLD   = 10   # ≥ 10 txns in window → high

  # ── Rule 2: Large Transaction Amounts ───────────────────────────────
  LARGE_SINGLE_THRESHOLD     = 10_000   # single outbound ≥ $10K  (CTR floor)
  LARGE_CUMULATIVE_THRESHOLD = 50_000   # 30-day cumulative outbound ≥ $50K
  LARGE_CRITICAL_THRESHOLD   = 200_000  # either metric ≥ $200K → critical

  # ── Rule 3: Unusual Geographic Activity ─────────────────────────────
  GEO_WINDOW_DAYS   = 7   # rolling window for multi-country check
  GEO_MIN_COUNTRIES = 3   # distinct counterparty countries in window → alert

  # ── Rule 4: Dormant Account Activity ────────────────────────────────
  DORMANT_LOOKBACK_DAYS = 90

  # ────────────────────────────────────────────────────────────────────

  def self.run(account_ids: nil, force_full_scan: false)
    new(account_ids: account_ids, force_full_scan: force_full_scan).run
  end

  def initialize(account_ids: nil, force_full_scan: false)
    @account_ids     = account_ids
    @force_full_scan = force_full_scan
    @created         = []
    @skipped         = []
    @accounts_scanned = 0
    @accounts_skipped_no_activity = 0
  end

  # Runs all detection rules on each qualifying account.
  # Returns:
  #   {
  #     created:                    [ { alert_id:, account_number:, customer:, rule:, severity: }, ... ],
  #     skipped:                    [ { account_number:, rule:, reason: }, ... ],
  #     accounts_scanned:           Integer,
  #     accounts_skipped_no_activity: Integer
  #   }
  def run
    accounts_scope.find_each do |account|
      @accounts_scanned += 1

      # `new_since` is the cutoff — rules only evaluate transactions AFTER this
      # point. This prevents re-flagging old transactions that were already
      # investigated when a previous alert was closed.
      # nil on first scan = no cutoff, evaluate all history.
      new_since = account.last_detected_at

      detect_high_frequency(account, new_since: new_since)
      detect_large_amounts(account, new_since: new_since)
      detect_unusual_geography(account, new_since: new_since)
      detect_dormant_activity(account, new_since: new_since)

      # Mark this account as scanned so next run skips it if no new activity
      account.update_column(:last_detected_at, Time.current)
    end

    log_summary
    {
      created:                      @created,
      skipped:                      @skipped,
      accounts_scanned:             @accounts_scanned,
      accounts_skipped_no_activity: @accounts_skipped_no_activity
    }
  end

  private

  # ── Account scope (incremental) ───────────────────────────────────────
  #
  # Unless force_full_scan is true, only return accounts that have at least
  # one transaction newer than their last_detected_at. This is the key
  # optimization: accounts with no new transactions cost zero queries.

  def accounts_scope
    scope = Account.includes(:customer)
    scope = scope.where(id: @account_ids) if @account_ids.present?
    scope = apply_incremental_filter(scope) unless @force_full_scan
    scope
  end

  def apply_incremental_filter(scope)
    # An account qualifies for re-scan when:
    #   a) it has never been scanned (last_detected_at IS NULL), OR
    #   b) it has a transaction (in or out) newer than its last scan
    #
    # This single EXISTS subquery avoids loading any transaction data —
    # it just checks whether new work exists before committing to a full scan.
    scope.where(
      "accounts.last_detected_at IS NULL OR EXISTS (" \
        "SELECT 1 FROM financial_transactions ft " \
        "WHERE (ft.from_account_id = accounts.id OR ft.to_account_id = accounts.id) " \
        "  AND ft.status = 'completed' " \
        "  AND ft.transacted_at > accounts.last_detected_at" \
      ")"
    ).tap do |filtered|
      # Log how many accounts were filtered out (informational only)
      total   = Account.count
      passing = filtered.count
      @accounts_skipped_no_activity = total - passing
    end
  end

  # ── Transaction helpers ───────────────────────────────────────────────

  # All completed transactions touching this account (inbound or outbound).
  def all_txns(account, since: nil)
    scope = FinancialTransaction
              .where(status: "completed")
              .where("from_account_id = :id OR to_account_id = :id", id: account.id)
    scope = scope.where("transacted_at >= ?", since) if since
    scope
  end

  # Completed outbound-only transactions.
  def outbound_txns(account, since: nil)
    scope = FinancialTransaction
              .where(status: "completed", from_account_id: account.id)
    scope = scope.where("transacted_at >= ?", since) if since
    scope
  end

  # ── Rule 1: High Transaction Frequency ───────────────────────────────
  #
  # Uses a natural rolling 24-hour window. `new_since` guards against
  # re-triggering if the same burst of transactions was already investigated.

  def detect_high_frequency(account, new_since:)
    rule = "HIGH_FREQUENCY"

    # The rolling window — transactions must be both recent AND new
    window_start = FREQ_WINDOW_HOURS.hours.ago
    since        = [new_since, window_start].compact.max

    txns  = all_txns(account, since: since).order(:transacted_at)
    count = txns.count

    return if count < FREQ_MEDIUM_THRESHOLD
    return if duplicate_open_alert?(account, rule)

    severity = count >= FREQ_HIGH_THRESHOLD ? "high" : "medium"

    create_alert!(
      account:     account,
      alert_type:  "High Transaction Frequency",
      rule:        rule,
      severity:    severity,
      txns:        txns,
      description: "Account recorded #{count} completed transactions within the last " \
                   "#{FREQ_WINDOW_HOURS} hours, exceeding the frequency threshold of " \
                   "#{FREQ_MEDIUM_THRESHOLD}. May indicate automated activity or layering " \
                   "through rapid transaction cycling.",
      metadata:    {
        transaction_count: count,
        window_hours:      FREQ_WINDOW_HOURS,
        medium_threshold:  FREQ_MEDIUM_THRESHOLD,
        high_threshold:    FREQ_HIGH_THRESHOLD
      }
    )
  end

  # ── Rule 2: Large Transaction Amounts ────────────────────────────────
  #
  # Only triggers on NEW transactions (since last_detected_at).
  # For the cumulative sub-rule we still compute the 30-day running total for
  # context/severity, but we only fire the alert when a new transaction is the
  # one that pushed it over the threshold — not for old transactions that were
  # already reviewed in a previous (now-closed) alert.

  def detect_large_amounts(account, new_since:)
    rule = "LARGE_AMOUNT"

    # Sub-rule A: NEW single outbound at or above the CTR threshold
    # new_since=nil on first scan means look at all history; subsequent scans
    # only look at transactions that arrived after the last detection run.
    single_large = outbound_txns(account, since: new_since)
                     .where("amount >= ?", LARGE_SINGLE_THRESHOLD)
                     .order(amount: :desc)

    # Sub-rule B: cumulative 30-day outbound — compute the total for context,
    # but only flag if there are NEW transactions contributing to it.
    new_outbound_in_window = outbound_txns(account, since: [new_since, 30.days.ago].compact.max)
    cumulative             = outbound_txns(account, since: 30.days.ago).sum(:amount).to_f

    flagged = single_large.to_a

    # Cumulative breach only triggers when the newly arrived transactions are
    # what pushed the rolling total over the threshold.
    if flagged.empty? && cumulative >= LARGE_CUMULATIVE_THRESHOLD && new_outbound_in_window.exists?
      flagged = outbound_txns(account, since: 30.days.ago).order(:transacted_at).to_a
    end

    return if flagged.empty?
    return if duplicate_open_alert?(account, rule)

    top = flagged.map { |t| t.amount.to_f }.max || 0.0

    severity =
      if top >= LARGE_CRITICAL_THRESHOLD || cumulative >= LARGE_CRITICAL_THRESHOLD
        "critical"
      elsif top >= LARGE_CUMULATIVE_THRESHOLD || cumulative >= LARGE_CUMULATIVE_THRESHOLD
        "high"
      else
        "medium"
      end

    create_alert!(
      account:     account,
      alert_type:  "Large Transaction Amount",
      rule:        rule,
      severity:    severity,
      txns:        flagged,
      description: "Account has #{flagged.size} outbound transaction(s) at or above the " \
                   "$#{fmt(LARGE_SINGLE_THRESHOLD)} CTR threshold. " \
                   "Largest single transaction: $#{fmt(top)}. " \
                   "Cumulative 30-day outbound: $#{fmt(cumulative)}.",
      metadata:    {
        largest_single_txn:      top.round(2),
        cumulative_30d_outbound: cumulative.round(2),
        single_txn_threshold:    LARGE_SINGLE_THRESHOLD,
        cumulative_threshold:    LARGE_CUMULATIVE_THRESHOLD,
        critical_threshold:      LARGE_CRITICAL_THRESHOLD
      }
    )
  end

  # ── Rule 3: Unusual Geographic Activity ──────────────────────────────
  #
  # Uses the 7-day window for context (distinct country count), but only
  # triggers when NEW transactions are the suspicious ones. This prevents
  # re-alerting on old high-risk transactions that were already investigated.

  def detect_unusual_geography(account, new_since:)
    rule         = "UNUSUAL_GEOGRAPHY"
    window_since = GEO_WINDOW_DAYS.days.ago

    # All recent txns in the 7-day window (for cumulative context like country count)
    recent_txns = all_txns(account, since: window_since)
                    .where.not(counterparty_country: [nil, ""])

    # NEW transactions only — these are the ones that could trigger a fresh alert
    new_txns = all_txns(account, since: [new_since, window_since].compact.max)
                 .where.not(counterparty_country: [nil, ""])

    # Sub-rule A: a NEW transaction touches a high-risk country
    new_high_risk_txns = new_txns.select { |t| HIGH_RISK_COUNTRIES.include?(t.counterparty_country) }

    # Sub-rule B: NEW transactions pushed the distinct-country count over the threshold
    distinct_countries  = recent_txns.map(&:counterparty_country).compact.uniq
    new_countries_added = new_txns.map(&:counterparty_country).compact.uniq

    multi_country_breach = new_countries_added.any? && distinct_countries.size >= GEO_MIN_COUNTRIES

    return unless new_high_risk_txns.any? || multi_country_breach
    return if duplicate_open_alert?(account, rule)

    if new_high_risk_txns.any?
      flagged     = new_high_risk_txns
      severity    = "high"
      risk_codes  = new_high_risk_txns.map(&:counterparty_country).uniq
      description = "Account has new transactions with counterparties in high-risk " \
                    "jurisdiction(s): #{risk_codes.join(', ')}. " \
                    "These countries appear on FATF/FinCEN watch lists."
    else
      flagged     = new_txns.to_a
      severity    = "medium"
      description = "Account transacted with counterparties in #{distinct_countries.size} " \
                    "different countries within #{GEO_WINDOW_DAYS} days " \
                    "(#{distinct_countries.join(', ')}). May indicate geographic layering."
    end

    create_alert!(
      account:     account,
      alert_type:  "Unusual Geographic Activity",
      rule:        rule,
      severity:    severity,
      txns:        flagged,
      description: description,
      metadata:    {
        high_risk_countries_involved: high_risk_txns.map(&:counterparty_country).uniq,
        all_distinct_countries:       distinct_countries,
        window_days:                  GEO_WINDOW_DAYS,
        high_risk_country_list:       HIGH_RISK_COUNTRIES
      }
    )
  end

  # ── Rule 4: Dormant Account Activity ─────────────────────────────────
  #
  # Only looks at transactions since `last_detected_at`. A dormant account
  # that was already investigated and cleared won't re-alert unless genuinely
  # new transactions arrive on it.

  def detect_dormant_activity(account, new_since:)
    return unless account.status == "dormant"

    rule  = "DORMANT_ACTIVITY"
    # On first scan use the full lookback window; on subsequent scans use
    # last_detected_at so we only catch genuinely new activity.
    since = new_since || DORMANT_LOOKBACK_DAYS.days.ago
    txns  = all_txns(account, since: since).order(:transacted_at)

    return if txns.empty?
    return if duplicate_open_alert?(account, rule)

    first_txn_date = txns.first&.transacted_at&.strftime("%Y-%m-%d")

    create_alert!(
      account:     account,
      alert_type:  "Dormant Account Activity",
      rule:        rule,
      severity:    "high",
      txns:        txns,
      description: "A dormant account recorded #{txns.count} transaction(s) since " \
                   "#{first_txn_date}, despite its dormant status. May indicate account " \
                   "takeover, unauthorized reactivation, or money mule activity.",
      metadata:    {
        account_status:      account.status,
        recent_txn_count:    txns.count,
        lookback_days:       DORMANT_LOOKBACK_DAYS,
        first_recent_txn_at: first_txn_date
      }
    )
  end

  # ── Alert persistence ─────────────────────────────────────────────────

  def create_alert!(account:, alert_type:, rule:, severity:, txns:, description:, metadata:)
    txn_refs = txns.map(&:txn_ref)

    alert = Alert.create!(
      alert_id:       generate_alert_id(rule),
      alert_type:     alert_type,
      severity:       severity,
      status:         "open",
      customer:       account.customer,
      account:        account,
      description:    description,
      rule_triggered: rule,
      txn_refs:       txn_refs,
      metadata:       metadata
    )

    entry = {
      alert_id:       alert.alert_id,
      account_number: account.account_number,
      customer:       account.customer.name,
      rule:           rule,
      severity:       severity
    }
    @created << entry
    Rails.logger.info("[AlertDetection] Created #{alert.alert_id} | #{rule} | #{severity.upcase} | #{account.account_number}")
    alert

  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[AlertDetection] Failed for #{account.account_number} (#{rule}): #{e.message}")
    nil
  end

  # Prevents duplicate open alerts for the same rule + account combination.
  def duplicate_open_alert?(account, rule)
    exists = Alert.where(account_id: account.id, rule_triggered: rule, status: "open").exists?
    if exists
      @skipped << { account_number: account.account_number, rule: rule, reason: "open_alert_exists" }
    end
    exists
  end

  # ── Utilities ─────────────────────────────────────────────────────────

  # e.g. "ALT-HF-3A9C1B2D-20260412120000"
  def generate_alert_id(rule)
    prefix = rule.split("_").map { |w| w[0] }.join.upcase  # HF, LA, UG, DA
    "ALT-#{prefix}-#{SecureRandom.hex(4).upcase}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  # Format number with commas and 2 decimal places, e.g. 10000.0 → "10,000.00"
  def fmt(amount)
    parts    = format("%.2f", amount).split(".")
    parts[0] = parts[0].chars.reverse.each_slice(3).map(&:join).join(",").reverse
    parts.join(".")
  end

  def log_summary
    Rails.logger.info(
      "[AlertDetection] Done — scanned #{@accounts_scanned} account(s), " \
      "#{@accounts_skipped_no_activity} skipped (no new activity), " \
      "#{@created.size} alert(s) created, #{@skipped.size} duplicate(s) skipped."
    )
  end
end
