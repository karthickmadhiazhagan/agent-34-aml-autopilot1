class CreateAlerts < ActiveRecord::Migration[7.1]
  def change
    create_table :alerts do |t|
      t.string  :alert_id,         null: false   # e.g. AML-2024-001
      t.string  :alert_type,       null: false   # Structuring, Rapid Movement, etc.
      t.string  :severity,         default: "medium"
      # low | medium | high | critical
      t.string  :status,           default: "open"
      # open | under_review | closed
      t.references :customer,      null: false, foreign_key: true
      t.references :account,       null: false, foreign_key: true
      t.text    :description
      t.string  :rule_triggered
      t.json    :txn_refs          # array of txn_ref strings belonging to this alert
      t.json    :metadata          # extra context: totals, time_period, risk_indicators, etc.
      t.timestamps
    end

    add_index :alerts, :alert_id, unique: true
    add_index :alerts, :severity
    add_index :alerts, :status
  end
end
