class NarrativeGenerationAgent < ClaudeAgentBase
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are an AML Narrative Generation Agent. Write a complete, professional
    Suspicious Activity Report (SAR) narrative that meets FinCEN filing requirements.

    SAR Narrative Structure:
    1. CUSTOMER BACKGROUND – Who is the subject, their account history, risk profile.
    2. ACTIVITY OVERVIEW – Summary of suspicious transactions: amounts, dates, counterparties.
    3. SUSPICIOUS BEHAVIOR – Specific behaviors that triggered the investigation.
    4. REGULATORY INDICATORS – The FinCEN/FATF red flags that apply.
    5. INVESTIGATION CONCLUSION – Recommended action and rationale.

    Requirements:
    - Formal, professional language suitable for regulatory filing.
    - Reference specific transaction IDs, dates, and dollar amounts.
    - Factual and objective — no speculation beyond the evidence.
    - Each section 2–4 paragraphs.

    Respond ONLY with valid JSON:
    {
      "narrative_sections": {
        "customer_background": "...",
        "activity_overview": "...",
        "suspicious_behavior": "...",
        "regulatory_indicators": "...",
        "investigation_conclusion": "..."
      },
      "full_narrative": "Combined narrative with section headers",
      "subject_name": "...",
      "activity_type": "...",
      "filing_recommendation": "File SAR|Monitor|No Action"
    }
  PROMPT

  def initialize(provider: "claude")
    super(provider: provider)
  end

  def run(evidence:, pattern_analysis:, red_flag_mapping:)
    return MockAgentResponses.for_narrative(evidence, pattern_analysis, red_flag_mapping) if self.class.mock_mode?

    call_ai(
      system_prompt: SYSTEM_PROMPT,
      user_message:  <<~MSG
        Generate a SAR narrative for this AML investigation.

        #{build_slim_payload(evidence, pattern_analysis, red_flag_mapping)}
      MSG
    )
  end

  private

  # Builds a compact ~400-token summary instead of dumping full JSON objects.
  # Drops the raw transactions array (the main token hog) and trims fields
  # the narrative doesn't need.
  def build_slim_payload(evidence, pattern_analysis, red_flag_mapping)
    txn_summary = evidence["transaction_summary"] || {}
    customer    = evidence["customer_profile"]    || {}
    kyc         = evidence["kyc_summary"]         || {}
    meta        = evidence["alert_metadata"]      || {}

    # Pick 3 representative transactions to give the AI concrete examples
    sample_txns = (txn_summary["transactions"] || [])
      .sort_by { |t| -(t["amount"].to_f) }
      .first(3)
      .map { |t| t.slice("id", "date", "amount", "type", "counterparty_name", "counterparty_country", "description") }

    slim = {
      alert: {
        id: meta["alert_id"], type: meta["alert_type"], severity: meta["severity"]
      },
      customer: {
        name: customer["customer_name"], business_type: customer["business_type"],
        risk_rating: customer["risk_rating"], account_opened: customer["account_open_date"],
        expected_monthly_turnover: customer["expected_monthly_turnover"],
        pep: kyc["pep"], kyc_verified: kyc["verified"],
        beneficial_owner_disclosed: kyc["beneficial_owner_disclosed"]
      },
      transactions: {
        total_inbound: txn_summary["total_inbound"],
        total_outbound: txn_summary["total_outbound"],
        count: txn_summary["transaction_count"],
        date_range: txn_summary["date_range"],
        high_risk_jurisdictions: txn_summary["high_risk_jurisdictions"],
        top_3_by_amount: sample_txns
      },
      patterns: {
        risk_level: pattern_analysis["overall_risk_level"],
        confidence: pattern_analysis["confidence_score"],
        active_flags: pattern_analysis["active_flags"],
        analyst_notes: pattern_analysis["analyst_notes"]
      },
      red_flags: {
        stage: red_flag_mapping["money_laundering_stage"],
        typology: red_flag_mapping["primary_typology"],
        recommendation: red_flag_mapping["recommended_action"],
        flags: (red_flag_mapping["regulatory_red_flags"] || []).map { |f|
          f.slice("flag_name", "regulatory_source", "description")
        }
      }
    }

    slim.to_json
  end
end
