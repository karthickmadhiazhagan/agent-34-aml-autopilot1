class EvidenceCollectionAgent < ClaudeAgentBase
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are an AML Evidence Collection Agent. Your role is to extract and structure
    all relevant investigation evidence from a raw AML alert payload.

    You MUST respond with ONLY valid JSON (no explanation, no markdown text outside the JSON block).
    Output the following structure exactly:

    {
      "customer_profile": { "customer_id": "...", "customer_name": "...", "business_type": "...", "account_open_date": "...", "expected_monthly_turnover": 0, "risk_rating": "..." },
      "kyc_summary": { "verified": bool, "pep": bool, "sanctions": bool, "last_review": "date", "beneficial_owner_disclosed": bool },
      "transaction_summary": {
        "total_inbound": number, "total_outbound": number, "transaction_count": number,
        "date_range": { "from": "date", "to": "date" },
        "high_risk_jurisdictions": ["country"],
        "transactions": [...]
      },
      "prior_sar_history": [],
      "alert_metadata": { "alert_id": "...", "alert_type": "...", "severity": "...", "generated_date": "..." }
    }
  PROMPT

  def initialize(provider: "claude")
    super(provider: provider)
  end

  def run(alert_data)
    return MockAgentResponses.for_evidence(alert_data) if self.class.mock_mode? || self.class.smart_mode?

    call_ai(
      system_prompt: SYSTEM_PROMPT,
      user_message:  "Extract structured evidence from this AML alert:\n\n#{alert_data.to_json}"
    )
  end
end
