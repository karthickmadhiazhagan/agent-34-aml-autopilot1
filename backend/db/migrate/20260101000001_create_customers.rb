class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.string  :customer_id,          null: false   # e.g. CUST_001
      t.string  :name,                 null: false
      t.string  :email
      t.string  :phone
      t.string  :nationality,          default: "US"
      t.string  :country_of_residence, default: "US"
      t.string  :occupation
      t.date    :date_of_birth
      t.integer :risk_score,           default: 0    # 0-100
      t.string  :kyc_status,           default: "verified"
      # verified | pending | failed | enhanced_due_diligence
      t.boolean :is_pep,               default: false  # Politically Exposed Person
      t.timestamps
    end

    add_index :customers, :customer_id, unique: true
  end
end
