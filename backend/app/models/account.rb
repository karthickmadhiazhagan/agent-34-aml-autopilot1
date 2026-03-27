class Account < ApplicationRecord
  belongs_to :customer
  has_many :alerts, dependent: :nullify
  has_many :outgoing_transactions, class_name: "FinancialTransaction", foreign_key: :from_account_id, dependent: :destroy
  has_many :incoming_transactions, class_name: "FinancialTransaction", foreign_key: :to_account_id,   dependent: :destroy

  def as_json_data
    {
      account_number: account_number,
      type:           account_type,
      balance:        balance.to_f,
      currency:       currency,
      status:         status,
      branch:         branch,
      opened_at:      opened_at&.to_s
    }
  end
end
