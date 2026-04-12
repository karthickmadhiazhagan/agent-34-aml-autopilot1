class AddLastDetectedAtToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :last_detected_at, :datetime, null: true, comment:
      "Timestamp of the last AlertDetectionService scan for this account. " \
      "Used for incremental detection — only accounts with transactions newer " \
      "than this value are re-scanned on each run."

    add_index :accounts, :last_detected_at, name: "index_accounts_on_last_detected_at"
  end
end
