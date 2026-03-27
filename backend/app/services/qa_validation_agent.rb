class QaValidationAgent < ClaudeAgentBase
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are an AML QA Validation Agent. Review a generated SAR narrative and
    validate it for accuracy, completeness, and regulatory compliance.

    Validation Checklist:
    1. TRANSACTION TOTALS – Do amounts in the narrative match the evidence?
    2. RED FLAGS COVERAGE – Are all identified red flags mentioned?
    3. SAR STRUCTURE – Are all 5 required sections present?
    4. FACTUAL ACCURACY – Does the narrative contain unsupported claims?
    5. REGULATORY REFERENCES – Are FinCEN/FATF references accurate?
    6. SUBJECT IDENTIFICATION – Is the subject correctly identified?
    7. DATE AND AMOUNT ACCURACY – Are specific dates and amounts correct?
    8. FILING RECOMMENDATION – Is the recommendation clearly stated?

    Respond ONLY with valid JSON:
    {
      "validation_passed": bool,
      "score": 0-100,
      "checks": [{ "check_name": "...", "passed": bool, "note": "..." }],
      "critical_issues": ["..."],
      "suggestions": ["..."],
      "qa_summary": "Overall quality assessment"
    }
  PROMPT

  def initialize(provider: "claude")
    super(provider: provider)
  end

  def run(evidence:, pattern_analysis:, narrative:)
    return MockAgentResponses.for_qa(evidence, pattern_analysis, narrative) if self.class.mock_mode? || self.class.smart_mode?

    call_ai(
      system_prompt: SYSTEM_PROMPT,
      user_message:  <<~MSG
        Validate this SAR narrative.

        Evidence:
        #{evidence.to_json}

        Pattern Analysis:
        #{pattern_analysis.to_json}

        Narrative:
        #{narrative.to_json}
      MSG
    )
  end
end
