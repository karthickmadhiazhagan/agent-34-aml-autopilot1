class Customer < ApplicationRecord
  has_many :accounts, dependent: :destroy
  has_many :alerts,   dependent: :destroy

  RISK_LABELS = {
    (0..30)  => "Low",
    (31..60) => "Medium",
    (61..80) => "High",
    (81..100) => "Critical"
  }.freeze

  def risk_label
    RISK_LABELS.find { |range, _| range.include?(risk_score) }&.last || "Unknown"
  end

  def as_json_data
    {
      id:                  customer_id,
      name:                name,
      email:               email,
      phone:               phone,
      nationality:         nationality,
      country_of_residence: country_of_residence,
      occupation:          occupation,
      date_of_birth:       date_of_birth&.to_s,
      risk_score:          risk_score,
      risk_label:          risk_label,
      kyc_status:          kyc_status,
      is_pep:              is_pep
    }
  end
end
