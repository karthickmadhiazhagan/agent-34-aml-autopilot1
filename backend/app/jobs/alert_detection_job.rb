# AlertDetectionJob
#
# Runs AlertDetectionService as an async background job.
# Zero AI involvement — pure SQL rule evaluation, no token cost.
#
# Triggered two ways:
#   1. Scheduled  – sidekiq-cron fires this every hour (config/schedule.yml)
#   2. On-demand  – AlertDetectionJob.perform_later or the rake task
#
# The service uses incremental scanning: only accounts with transactions
# newer than their last_detected_at are processed, so hourly runs are cheap
# even with large account sets.
#
class AlertDetectionJob < ApplicationJob
  queue_as :alert_detection

  # Optional: pass specific account IDs or force a full re-scan
  # AlertDetectionJob.perform_later
  # AlertDetectionJob.perform_later(account_ids: [1, 2, 3])
  # AlertDetectionJob.perform_later(force_full_scan: true)
  def perform(account_ids: nil, force_full_scan: false)
    Rails.logger.info("[AlertDetectionJob] Starting | account_ids=#{account_ids.inspect} | force_full_scan=#{force_full_scan}")
    start_time = Time.current

    result = AlertDetectionService.run(
      account_ids:     account_ids,
      force_full_scan: force_full_scan
    )

    elapsed = (Time.current - start_time).round(2)

    Rails.logger.info(
      "[AlertDetectionJob] Complete in #{elapsed}s | " \
      "accounts_scanned=#{result[:accounts_scanned]} | " \
      "accounts_skipped_no_activity=#{result[:accounts_skipped_no_activity]} | " \
      "alerts_created=#{result[:created].size} | " \
      "duplicates_skipped=#{result[:skipped].size}"
    )

    result
  end
end
