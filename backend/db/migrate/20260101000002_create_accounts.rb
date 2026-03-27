class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.references :customer,      null: false, foreign_key: true
      t.string  :account_number,   null: false
      t.string  :account_type,     default: "checking"
      # checking | savings | business | offshore
      t.decimal :balance,          precision: 15, scale: 2, default: 0
      t.string  :currency,         default: "USD"
      t.string  :status,           default: "active"
      # active | frozen | closed | dormant
      t.string  :branch
      t.date    :opened_at
      t.timestamps
    end

    add_index :accounts, :account_number, unique: true
  end
end
