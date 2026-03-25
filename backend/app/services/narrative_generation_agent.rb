# Agent 4 – Narrative Generation Agent
# Generates a complete SAR-ready investigation narrative.
class NarrativeGenerationAgent < ClaudeAgentBase
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are an AML Narrative Generation Agent. Your role is to write a complete,
    professional Suspicious Activity Report (SAR) narrative that meets FinCEN filing
    requirements.

    SAR Narrative Structure (follow this exactly):
    1. CUSTOMER BACKGROUND – Who is the subject, their account history, risk profile.
    2. ACTIVITY OVERVIEW – Summary of the suspicious transactions: amounts, dates, counterparties.
    3. SUSPICIOUS BEHAVIOR – Specific behaviors that triggered the investigation.
    4. REGULATORY INDICATORS – The FinCEN/FATF red flags that apply.
    5. INVESTIGATION CONCLUSION – Recommended action and rationale.

    Requirements:
    - Write in formal, professional language suitable for regulatory filing.
    - Reference specific transaction IDs, dates, and dollar amounts.
    - Be factual and objective — no speculation beyond the evidence.
    - Each section should be 2–4 paragraphs.

    Respond ONLY with valid JSON:
    {
      "narrative_sections": {
        "customer_background": "...",
        "activity_overview": "...",
        "suspicious_behavior": "...",
        "regulatory_indicators": "...",
        "investigation_conclusion": "..."
      },
      "full_narrative": "Combined narrative text with section headers",
      "subject_name": "...",
      "activity_type": "...",
      "filing_recommendation": "File SAR|Monitor|No Action"
    }
  PROMPT

  def run(evidence:, pattern_analysis:, red_flag_mapping:)
    return MockAgentResponses.for_narrative(evidence, pattern_analysis, red_flag_mapping) if self.class.mock_mode?

    call_claude(
      system_prompt: SYSTEM_PROMPT,
      user_message:  <<~MSG
        Generate a SAR narrative for this AML investigation.

        Evidence Package:
        #{evidence.to_json}

        Pattern Analysis:
        #{pattern_analysis.to_json}

        Red Flag Mapping:
        #{red_flag_mapping.to_json}
      MSG
    )
  end
end
