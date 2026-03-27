class CreateFinancialTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :financial_transactions do |t|
      t.string  :txn_ref,          null: false   # e.g. TXN-2024-00001
      t.references :from_account,  foreign_key: { to_table: :accounts }, null: true
      t.references :to_account,    foreign_key: { to_table: :accounts }, null: true
      t.decimal :amount,           precision: 15, scale: 2
      t.string  :currency,         default: "USD"
      t.string  :txn_type
      # wire_transfer | cash_deposit | cash_withdrawal | ach_transfer | check | crypto_conversion
      t.text    :description
      t.string  :location
      t.string  :counterparty_name    # external bank / person name when no internal account
      t.string  :counterparty_country # originating country for wires
      t.string  :status,           default: "completed"
      t.datetime :transacted_at,   null: false
      t.timestamps
    end

    add_index :financial_transactions, :txn_ref, unique: true
    add_index :financial_transactions, :transacted_at
  end
end
