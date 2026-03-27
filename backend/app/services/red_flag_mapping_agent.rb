class RedFlagMappingAgent < ClaudeAgentBase
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are an AML Red Flag Mapping Agent. Map detected suspicious activity patterns
    to official regulatory red flag indicators from FinCEN and FATF.

    FinCEN categories: Layering, Placement, Integration, Structuring/Smurfing,
    Third-Party Payment Patterns, Unusual Wire Transfer Activity, Business Profile
    Inconsistency, Funnel Account Activity.

    FATF flags: Unusual transaction patterns, Rapid movement of funds, High-risk
    jurisdictions, PEP-linked transactions, Prior SAR activity.

    Respond ONLY with valid JSON:
    {
      "regulatory_red_flags": [{
        "flag_name": "...", "regulatory_source": "FinCEN|FATF",
        "category": "...", "mapped_from_pattern": "...",
        "description": "...", "risk_weight": "High|Medium|Low"
      }],
      "money_laundering_stage": "Placement|Layering|Integration|Unknown",
      "primary_typology": "...",
      "recommended_action": "File SAR|Monitor|Close Account|Escalate"
    }
  PROMPT

  def initialize(provider: "claude")
    super(provider: provider)
  end

  def run(evidence:, pattern_analysis:)
    return MockAgentResponses.for_red_flag_mapping(evidence, pattern_analysis) if self.class.mock_mode? || self.class.smart_mode?

    call_ai(
      system_prompt: SYSTEM_PROMPT,
      user_message:  "Map red flags.\n\nEvidence:\n#{evidence.to_json}\n\nPatterns:\n#{pattern_analysis.to_json}"
    )
  end
end
