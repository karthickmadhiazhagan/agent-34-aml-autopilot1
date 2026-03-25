# Agent 5 – QA Validation Agent
# Validates the generated narrative for accuracy, completeness, and SAR compliance.
class QaValidationAgent < ClaudeAgentBase
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are an AML QA Validation Agent. Your role is to review a generated SAR narrative
    and validate it for accuracy, completeness, and regulatory compliance.

    Validation Checklist:
    1. TRANSACTION TOTALS – Do the inbound/outbound amounts in the narrative match the evidence?
    2. PASS-THROUGH RATIO – Is the ratio correctly calculated and stated if applicable?
    3. RED FLAGS COVERAGE – Are all identified red flags mentioned in the narrative?
    4. SAR STRUCTURE – Are all 5 required sections present and adequately written?
    5. FACTUAL ACCURACY – Does the narrative contain claims not supported by the evidence?
    6. REGULATORY REFERENCES – Are FinCEN/FATF references accurate and appropriate?
    7. SUBJECT IDENTIFICATION – Is the subject correctly and completely identified?
    8. DATE AND AMOUNT ACCURACY – Are specific dates and dollar amounts correct?

    Respond ONLY with valid JSON:
    {
      "validation_passed": true/false,
      "score": 0-100,
      "checks": [
        {
          "check_name": "...",
          "passed": true/false,
          "note": "..."
        }
      ],
      "critical_issues": ["list of critical problems if any"],
      "suggestions": ["improvement suggestions"],
      "qa_summary": "Overall quality assessment paragraph"
    }
  PROMPT

  def run(evidence:, pattern_analysis:, narrative:)
    return MockAgentResponses.for_qa(evidence, pattern_analysis, narrative) if self.class.mock_mode?

    call_claude(
      system_prompt: SYSTEM_PROMPT,
      user_message:  <<~MSG
        Validate this SAR narrative against the underlying evidence.

        Evidence:
        #{evidence.to_json}

        Pattern Analysis:
        #{pattern_analysis.to_json}

        Generated Narrative:
        #{narrative.to_json}
      MSG
    )
  end
end
