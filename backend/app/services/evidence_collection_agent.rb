# Agent 1 – Evidence Collection Agent
# Extracts and structures all relevant investigation evidence from the raw alert.
class EvidenceCollectionAgent < ClaudeAgentBase
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are an AML Evidence Collection Agent. Your role is to extract and structure
    all relevant investigation evidence from a raw AML alert payload.

    You MUST respond with ONLY valid JSON (no explanation, no markdown text outside the JSON block).
    Output the following structure exactly:

    {
      "customer_profile": { ... },
      "kyc_summary": { "verified": bool, "pep": bool, "sanctions": bool, "last_review": "date", "beneficial_owner_disclosed": bool },
      "transaction_summary": {
        "total_inbound": number,
        "total_outbound": number,
        "transaction_count": number,
        "date_range": { "from": "date", "to": "date" },
        "high_risk_jurisdictions": ["country", ...],
        "transactions": [...]
      },
      "prior_sar_history": [...],
      "alert_metadata": { "alert_id": "...", "alert_type": "...", "severity": "...", "generated_date": "..." }
    }
  PROMPT

  def run(alert_data)
    return MockAgentResponses.for_evidence(alert_data) if self.class.mock_mode?

    call_claude(
      system_prompt: SYSTEM_PROMPT,
      user_message:  "Extract structured evidence from this AML alert:\n\n#{alert_data.to_json}"
    )
  end
end
