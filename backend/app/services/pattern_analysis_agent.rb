class PatternAnalysisAgent < ClaudeAgentBase
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are an AML Pattern Analysis Agent. Analyze the provided transaction evidence
    and detect suspicious patterns using these AML detection rules:

    RULE 1 – Rapid Pass-Through: (outbound / inbound) >= 0.90 AND funds transferred within 24 hours.
    RULE 2 – Funnel Account: 10 or more distinct originators send funds to the same account.
    RULE 3 – Business Profile Mismatch: total inbound > 2x the customer's expected monthly turnover.
    RULE 4 – Structuring / Smurfing: multiple cash deposits just below $10,000 within a short period.
    RULE 5 – High-Risk Jurisdiction: transactions involve countries flagged as high-risk.
    RULE 6 – PEP / Sanctions Link: customer or counterparty is linked to a PEP or sanctions list.

    Respond ONLY with valid JSON:
    {
      "detected_patterns": [{ "rule": "...", "triggered": bool, "evidence": "...", "severity": "Low|Medium|High|Critical" }],
      "active_flags": ["flag1"],
      "confidence_score": 0.0,
      "overall_risk_level": "Low|Medium|High|Critical",
      "analyst_notes": "..."
    }
  PROMPT

  def initialize(provider: "claude")
    super(provider: provider)
  end

  def run(evidence)
    return MockAgentResponses.for_pattern_analysis(evidence) if self.class.mock_mode?

    call_ai(
      system_prompt: SYSTEM_PROMPT,
      user_message:  "Analyze these transaction patterns:\n\n#{evidence.to_json}"
    )
  end
end
