class FinancialTransaction < ApplicationRecord
  belongs_to :from_account, class_name: "Account", optional: true
  belongs_to :to_account,   class_name: "Account", optional: true

  def as_json_data
    {
      id:                  txn_ref,
      type:                txn_type,
      amount:              amount.to_f,
      currency:            currency,
      from_account:        from_account&.account_number || counterparty_name,
      to_account:          to_account&.account_number,
      description:         description,
      date:                transacted_at&.strftime("%Y-%m-%d %H:%M"),
      location:            location,
      counterparty_name:   counterparty_name,
      counterparty_country: counterparty_country,
      status:              status
    }
  end
end
