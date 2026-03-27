# InvestigationOrchestrator – Two-phase pipeline matching the AML process flowchart.
#
# Phase 1 (run):
#   Alert Ingestion → Evidence Collection → Pattern Analysis →
#   Red Flag Mapping → Narrative Generation → QA Validation
#   → status: narrative_ready  (human review gate)
#
# Phase 2 (generate_sar) — called only after narrative_approved:
#   SAR composition → status: sar_ready  (human review gate)
#
# Regenerate narrative — re-runs Narrative + QA agents with existing evidence:
#   → status: narrative_ready  (human review gate again)
class InvestigationOrchestrator
  def initialize(investigation)
    @investigation = investigation
    @provider = investigation.ai_provider.presence || "claude"
  end

  # ── Phase 1 ──────────────────────────────────────────────────────────────
  def run
    @investigation.running!

    # Step 1 – Load alert data (already stored on the investigation by the controller)
    alert_data = @investigation.alert_data_parsed
    raise "Alert data missing for #{@investigation.alert_id}" unless alert_data

    # Step 2 – Evidence Collection Agent
    evidence = EvidenceCollectionAgent.new(provider: @provider).run(alert_data)
    @investigation.update!(evidence: evidence.to_json)

    # Step 3 – Pattern Analysis Agent
    pattern_analysis = PatternAnalysisAgent.new(provider: @provider).run(evidence)
    @investigation.update!(pattern_analysis: pattern_analysis.to_json)

    # Step 4 – Red Flag Mapping Agent
    red_flag_mapping = RedFlagMappingAgent.new(provider: @provider).run(
      evidence: evidence,
      pattern_analysis: pattern_analysis
    )
    @investigation.update!(red_flag_mapping: red_flag_mapping.to_json)

    # Step 5 – Narrative Generation Agent
    narrative = NarrativeGenerationAgent.new(provider: @provider).run(
      evidence: evidence,
      pattern_analysis: pattern_analysis,
      red_flag_mapping: red_flag_mapping
    )

    # Step 6 – QA Validation Agent
    qa_result = QaValidationAgent.new(provider: @provider).run(
      evidence: evidence,
      pattern_analysis: pattern_analysis,
      narrative: narrative
    )

    # ── Human review gate: stop here, set narrative_ready ──────────────────
    @investigation.narrative_ready!(
      narrative: narrative.to_json,
      qa_result: qa_result.to_json
    )

    @investigation
  rescue StandardError => e
    @investigation.failed!(e.message)
    raise
  end

  # ── Regenerate narrative (Phase 1b) ──────────────────────────────────────
  # Note: caller (controller) already called running! and increment_regeneration!
  def regenerate_narrative

    evidence         = @investigation.evidence_parsed
    pattern_analysis = @investigation.pattern_analysis_parsed
    red_flag_mapping = @investigation.red_flag_mapping_parsed

    raise "Missing evidence – run Phase 1 first" unless evidence

    # Re-run only Narrative + QA agents
    narrative = NarrativeGenerationAgent.new(provider: @provider).run(
      evidence: evidence,
      pattern_analysis: pattern_analysis,
      red_flag_mapping: red_flag_mapping
    )

    qa_result = QaValidationAgent.new(provider: @provider).run(
      evidence: evidence,
      pattern_analysis: pattern_analysis,
      narrative: narrative
    )

    @investigation.narrative_ready!(
      narrative: narrative.to_json,
      qa_result: qa_result.to_json
    )

    @investigation
  rescue StandardError => e
    @investigation.failed!(e.message)
    raise
  end

  # ── Phase 2: Generate SAR (called after narrative_approved) ──────────────
  def generate_sar
    evidence         = @investigation.evidence_parsed
    pattern_analysis = @investigation.pattern_analysis_parsed
    red_flag_mapping = @investigation.red_flag_mapping_parsed
    narrative        = @investigation.narrative_parsed
    qa_result        = @investigation.qa_result_parsed

    sar = build_sar_output(evidence, pattern_analysis, red_flag_mapping, narrative, qa_result)
    @investigation.sar_ready!(sar_output: sar.to_json)

    @investigation
  rescue StandardError => e
    @investigation.failed!(e.message)
    raise
  end

  # ── Revise SAR (re-composes SAR, keeps existing narrative) ───────────────
  def revise_sar
    generate_sar
  end

  private

  def build_sar_output(evidence, pattern_analysis, red_flag_mapping, narrative, qa_result)
    {
      sar_version:  "1.0",
      generated_at: Time.current.iso8601,
      alert_id:     @investigation.alert_id,
      subject: {
        name:          evidence.dig("customer_profile", "customer_name"),
        customer_id:   evidence.dig("customer_profile", "customer_id"),
        business_type: evidence.dig("customer_profile", "business_type"),
        risk_rating:   evidence.dig("customer_profile", "risk_rating"),
        account_open_date: evidence.dig("customer_profile", "account_open_date")
      },
      activity_type:          narrative["activity_type"],
      filing_recommendation:  narrative["filing_recommendation"],
      red_flags:              red_flag_mapping["regulatory_red_flags"]&.map { |f| f["flag_name"] },
      regulatory_red_flags:   red_flag_mapping["regulatory_red_flags"],
      money_laundering_stage: red_flag_mapping["money_laundering_stage"],
      primary_typology:       red_flag_mapping["primary_typology"],
      recommended_action:     red_flag_mapping["recommended_action"],
      confidence_score:       pattern_analysis["confidence_score"],
      overall_risk_level:     pattern_analysis["overall_risk_level"],
      active_flags:           pattern_analysis["active_flags"],
      qa_score:               qa_result["score"],
      qa_passed:              qa_result["validation_passed"],
      narrative_sections:     narrative["narrative_sections"],
      full_narrative:         narrative["full_narrative"],
      transaction_summary: {
        total_inbound:     evidence.dig("transaction_summary", "total_inbound"),
        total_outbound:    evidence.dig("transaction_summary", "total_outbound"),
        transaction_count: evidence.dig("transaction_summary", "transaction_count"),
        date_range:        evidence.dig("transaction_summary", "date_range"),
        high_risk_jurisdictions: evidence.dig("transaction_summary", "high_risk_jurisdictions")
      },
      kyc_summary:       evidence["kyc_summary"],
      prior_sar_history: evidence["prior_sar_history"],
      regeneration_count: @investigation.regeneration_count
    }
  end
end
