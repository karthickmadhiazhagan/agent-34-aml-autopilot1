namespace :aml do
  desc <<~DESC
    Enqueue AlertDetectionJob to scan accounts and create AML alerts.

    Detection is 100% rule-based — no AI, no token cost. AI is only
    invoked later, per-alert, when a human explicitly starts an Investigation.

    The job uses incremental scanning: only accounts with transactions newer
    than their last_detected_at timestamp are scanned. Accounts with no new
    activity are skipped entirely.

    Four detection rules:
      HIGH_FREQUENCY    – >= 5 transactions in the last 24 hours
      LARGE_AMOUNT      – single txn >= $10K or 30-day cumulative outbound >= $50K
      UNUSUAL_GEOGRAPHY – transactions with FATF/FinCEN high-risk countries
      DORMANT_ACTIVITY  – dormant account shows recent transaction activity

    Options (all optional):
      ACCOUNT_IDS=1,2,3     Comma-separated account IDs to scan (default: all)
      FORCE_FULL_SCAN=true  Ignore last_detected_at, scan all accounts
      SYNC=true             Run inline (blocking) instead of enqueueing to Sidekiq
                            Useful for local dev without Redis running

    Examples:
      rails aml:detect_alerts
      rails aml:detect_alerts ACCOUNT_IDS=5,12,33
      rails aml:detect_alerts FORCE_FULL_SCAN=true
      rails aml:detect_alerts SYNC=true
  DESC
  task detect_alerts: :environment do
    account_ids     = ENV["ACCOUNT_IDS"]&.split(",")&.map(&:strip)&.map(&:to_i).presence
    force_full_scan = ENV["FORCE_FULL_SCAN"] == "true"
    sync            = ENV["SYNC"] == "true"

    puts ""
    puts "=" * 62
    puts "  AML Alert Detection"
    puts "=" * 62
    puts "  Mode            : #{sync ? 'SYNC (inline)' : 'ASYNC (Sidekiq)'}"
    puts "  Scan scope      : #{account_ids ? "accounts #{account_ids.join(', ')}" : 'all accounts (incremental)'}"
    puts "  Force full scan : #{force_full_scan}"
    puts "=" * 62
    puts ""

    if sync
      # Run directly — useful in dev without Redis
      result = AlertDetectionService.run(
        account_ids:     account_ids,
        force_full_scan: force_full_scan
      )
      print_result(result)
    else
      # Enqueue to Sidekiq — normal production path
      AlertDetectionJob.perform_later(
        account_ids:     account_ids,
        force_full_scan: force_full_scan
      )
      puts "  ✅ Job enqueued to Sidekiq queue: alert_detection"
      puts "  Check Sidekiq logs or the Web UI for progress."
      puts ""
    end
  end

  # ── Helper ─────────────────────────────────────────────────────────────

  def print_result(result)
    created = result[:created]
    skipped = result[:skipped]

    puts "  Accounts scanned : #{result[:accounts_scanned]}"
    puts "  Accounts skipped (no new activity) : #{result[:accounts_skipped_no_activity]}"
    puts ""

    if created.any?
      puts "  ✅ Alerts Created (#{created.size}):"
      created.each do |a|
        sev = a[:severity].upcase.ljust(8)
        puts "     [#{sev}] #{a[:alert_id]}  |  #{a[:rule].ljust(20)}  |  #{a[:account_number]}  (#{a[:customer]})"
      end
    else
      puts "  No new alerts created."
    end

    puts ""

    if skipped.any?
      puts "  ⏭  Duplicates Skipped (#{skipped.size}):"
      skipped.each do |s|
        puts "     #{s[:rule].ljust(20)}  |  #{s[:account_number]}"
      end
    end

    puts ""
    puts "-" * 62
    puts "  Total created : #{created.size}"
    puts "  Total skipped : #{skipped.size}"
    puts "-" * 62
    puts ""
  end
end
