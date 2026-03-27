# MockAgentResponses – Returns realistic pre-built responses for each agent
# when MOCK_AI=true. Lets you run the full pipeline without API credits.
module MockAgentResponses
  def self.for_evidence(alert_data)
    # alert_data is parsed from JSON so all keys are strings
    customer = alert_data["customer"] || {}
    account  = alert_data["account"]  || {}
    txns     = alert_data["transactions"] || []
    meta     = alert_data["metadata"] || {}

    # Compute inbound / outbound from transaction types
    inbound  = txns.select { |t| t["type"] == "cash_deposit" || t["type"] == "crypto_conversion" || t["from_account"].nil? }
    outbound = txns - inbound
    total_in  = inbound.sum  { |t| t["amount"].to_f }
    total_out = outbound.sum { |t| t["amount"].to_f }

    # Extract high-risk counterparty countries
    high_risk_countries = %w[RU IR KP SY CU BVI CYM PAN CYP UA MX MU PA KY HK EE VG]
    countries = txns.map { |t| t["counterparty_country"] }.compact.uniq
    high_risk = countries & high_risk_countries

    dates = txns.map { |t| t["date"] }.compact.sort

    {
      "customer_profile" => {
        "customer_id"               => customer["id"],
        "customer_name"             => customer["name"],
        "business_type"             => customer["occupation"] || "Individual",
        "account_open_date"         => account["opened_at"] || "N/A",
        "expected_monthly_turnover" => (account["balance"].to_f / 6).round(2),
        "risk_rating"               => customer["risk_label"] || "High"
      },
      "kyc_summary" => {
        "verified"                   => customer["kyc_status"] == "verified",
        "pep"                        => customer["is_pep"] || false,
        "sanctions"                  => false,
        "last_review"                => "2024-01-01",
        "beneficial_owner_disclosed" => customer["kyc_status"] != "pending"
      },
      "transaction_summary" => {
        "total_inbound"           => total_in.round(2),
        "total_outbound"          => total_out.round(2),
        "transaction_count"       => txns.size,
        "date_range"              => {
          "from" => dates.first || "N/A",
          "to"   => dates.last  || "N/A"
        },
        "high_risk_jurisdictions" => high_risk,
        "transactions"            => txns
      },
      "prior_sar_history" => [],
      "alert_metadata" => {
        "alert_id"       => alert_data["alert_id"],
        "alert_type"     => alert_data["alert_type"],
        "severity"       => alert_data["severity"],
        "generated_date" => Time.current.strftime("%Y-%m-%d"),
        "rule_triggered" => meta["rule_triggered"],
        "risk_indicators" => meta["risk_indicators"] || []
      }
    }
  end

  def self.for_pattern_analysis(evidence)
    inbound   = evidence.dig("transaction_summary", "total_inbound").to_f
    outbound  = evidence.dig("transaction_summary", "total_outbound").to_f
    expected  = evidence.dig("customer_profile", "expected_monthly_turnover").to_f
    ratio     = inbound > 0 ? outbound / inbound : 0
    high_risk = evidence.dig("transaction_summary", "high_risk_jurisdictions") || []
    pep       = evidence.dig("kyc_summary", "pep") || false

    patterns = [
      {
        "rule"      => "Rapid Pass-Through",
        "triggered" => ratio >= 0.90,
        "evidence"  => "Outbound/Inbound ratio is #{(ratio * 100).round(1)}% (threshold: 90%)",
        "severity"  => ratio >= 0.90 ? "High" : "Low"
      },
      {
        "rule"      => "Business Profile Mismatch",
        "triggered" => inbound > expected * 2,
        "evidence"  => "Inbound ($#{inbound.to_i}) exceeds 2× expected monthly turnover ($#{(expected * 2).to_i})",
        "severity"  => inbound > expected * 2 ? "High" : "Low"
      },
      {
        "rule"      => "High-Risk Jurisdiction",
        "triggered" => high_risk.any?,
        "evidence"  => high_risk.any? ? "Transactions involve high-risk jurisdictions: #{high_risk.join(', ')}" : "No high-risk jurisdictions detected",
        "severity"  => high_risk.any? ? "High" : "Low"
      },
      {
        "rule"      => "PEP / Sanctions Link",
        "triggered" => pep,
        "evidence"  => pep ? "Customer is flagged as a Politically Exposed Person (PEP)" : "No PEP or sanctions links detected",
        "severity"  => pep ? "Critical" : "Low"
      }
    ]

    active = patterns.select { |p| p["triggered"] }.map { |p| p["rule"] }
    score  = [0.55 + (active.size * 0.10), 0.98].min.round(2)
    level  = case active.size
             when 0    then "Low"
             when 1    then "Medium"
             when 2    then "High"
             else           "Critical"
             end

    {
      "detected_patterns"  => patterns,
      "active_flags"       => active,
      "confidence_score"   => score,
      "overall_risk_level" => level,
      "analyst_notes"      => "#{active.size} AML pattern(s) triggered. Primary concern: #{active.first || 'none'}. Full investigator review recommended."
    }
  end

  def self.for_red_flag_mapping(evidence, pattern_analysis)
    flags      = pattern_analysis["active_flags"] || []
    stage      = flags.include?("Rapid Pass-Through") ? "Layering" : "Placement"
    typology   = flags.include?("Rapid Pass-Through") ? "Pass-Through / Funnel Account" : "Structuring / Smurfing"
    rec_action = flags.size >= 2 ? "File SAR" : "Monitor"

    regulatory_flags = []

    if flags.include?("Rapid Pass-Through")
      regulatory_flags << {
        "flag_name"           => "Rapid Movement of Funds",
        "regulatory_source"   => "FinCEN",
        "category"            => "Layering Indicators",
        "mapped_from_pattern" => "Rapid Pass-Through",
        "description"         => "Funds received and rapidly disbursed suggest layering to obscure origin.",
        "risk_weight"         => "High"
      }
    end

    if flags.include?("Business Profile Mismatch")
      regulatory_flags << {
        "flag_name"           => "Business Profile Inconsistency",
        "regulatory_source"   => "FATF",
        "category"            => "Unusual Transaction Patterns",
        "mapped_from_pattern" => "Business Profile Mismatch",
        "description"         => "Transaction volume significantly exceeds the customer's declared business activity.",
        "risk_weight"         => "High"
      }
    end

    if flags.include?("High-Risk Jurisdiction")
      regulatory_flags << {
        "flag_name"           => "High-Risk Jurisdiction Transactions",
        "regulatory_source"   => "FATF",
        "category"            => "Geographic Risk Indicators",
        "mapped_from_pattern" => "High-Risk Jurisdiction",
        "description"         => "Transactions routed through jurisdictions with weak AML controls.",
        "risk_weight"         => "High"
      }
    end

    if flags.include?("PEP / Sanctions Link")
      regulatory_flags << {
        "flag_name"           => "PEP-Linked Transaction Activity",
        "regulatory_source"   => "FinCEN",
        "category"            => "PEP / Sanctions Indicators",
        "mapped_from_pattern" => "PEP / Sanctions Link",
        "description"         => "Customer is a Politically Exposed Person, increasing risk of corruption-related proceeds.",
        "risk_weight"         => "Critical"
      }
    end

    if regulatory_flags.empty?
      regulatory_flags << {
        "flag_name"           => "Unusual Wire Transfer Activity",
        "regulatory_source"   => "FinCEN",
        "category"            => "Unusual Wire Activity",
        "mapped_from_pattern" => "General Alert",
        "description"         => "Wire transfer patterns deviate from expected customer behavior profile.",
        "risk_weight"         => "Medium"
      }
    end

    {
      "regulatory_red_flags"   => regulatory_flags,
      "money_laundering_stage" => stage,
      "primary_typology"       => typology,
      "recommended_action"     => rec_action
    }
  end

  def self.for_narrative(evidence, pattern_analysis, red_flag_mapping)
    name      = evidence.dig("customer_profile", "customer_name") || "Unknown Subject"
    biz_type  = evidence.dig("customer_profile", "business_type") || "Unknown"
    inbound   = evidence.dig("transaction_summary", "total_inbound").to_i
    outbound  = evidence.dig("transaction_summary", "total_outbound").to_i
    txn_count = evidence.dig("transaction_summary", "transaction_count").to_i
    from      = evidence.dig("transaction_summary", "date_range", "from") || "N/A"
    to_date   = evidence.dig("transaction_summary", "date_range", "to") || "N/A"
    flags     = red_flag_mapping["regulatory_red_flags"]&.map { |f| f["flag_name"] } || []
    stage     = red_flag_mapping["money_laundering_stage"] || "Unknown"
    typology  = red_flag_mapping["primary_typology"] || "Unknown"
    risk      = pattern_analysis["overall_risk_level"] || "High"
    rec       = red_flag_mapping["recommended_action"] || "File SAR"
    filing    = rec == "File SAR" ? "File SAR" : "Monitor"

    sections = {
      "customer_background" =>
        "#{name} is a #{biz_type} customer whose account was opened on #{evidence.dig('customer_profile', 'account_open_date')}. " \
        "The account carries a #{evidence.dig('customer_profile', 'risk_rating')} risk rating with an expected monthly " \
        "turnover of $#{evidence.dig('customer_profile', 'expected_monthly_turnover').to_i.then { |v| ActiveSupport::NumberHelper.number_to_delimited(v) }}. " \
        "KYC verification status: #{evidence.dig('kyc_summary', 'verified') ? 'verified' : 'unverified'}. " \
        "Beneficial owner disclosure: #{evidence.dig('kyc_summary', 'beneficial_owner_disclosed') ? 'complete' : 'incomplete'}.",

      "activity_overview" =>
        "Between #{from} and #{to_date}, the account processed #{txn_count} transactions totalling " \
        "$#{ActiveSupport::NumberHelper.number_to_delimited(inbound)} inbound and " \
        "$#{ActiveSupport::NumberHelper.number_to_delimited(outbound)} outbound. " \
        "The funds were received from multiple counterparties and rapidly disbursed to third-party beneficiaries, " \
        "several of which are domiciled in high-risk jurisdictions. " \
        "The volume of activity substantially exceeds the customer's declared business profile.",

      "suspicious_behavior" =>
        "The primary suspicious behavior observed is consistent with #{typology}. " \
        "Funds were received and disbursed within compressed timeframes, indicating the account may be functioning " \
        "as a conduit rather than for legitimate commercial purposes. " \
        "The pass-through ratio and transaction velocity are inconsistent with the declared business activity of a #{biz_type}. " \
        "Multiple counterparties involved in the transactions have no apparent business relationship with the subject.",

      "regulatory_indicators" =>
        "This activity maps to the following regulatory red flags: #{flags.join('; ')}. " \
        "Under FinCEN guidance and FATF Recommendation 20, these patterns are consistent with the #{stage} " \
        "stage of money laundering. The overall risk level has been assessed as #{risk} with a confidence " \
        "score of #{(pattern_analysis['confidence_score'].to_f * 100).round(0)}% by the automated pattern analysis engine.",

      "investigation_conclusion" =>
        "Based on the totality of the evidence, transaction analysis, and regulatory red flag mapping, " \
        "this investigation has determined that the activity warrants a #{filing}. " \
        "The subject account exhibits characteristics consistent with #{typology}, a recognized AML typology. " \
        "It is recommended that this matter be escalated for senior review and that a Suspicious Activity Report " \
        "be filed with FinCEN in accordance with 31 U.S.C. § 5318(g)."
    }

    full = sections.map { |k, v| "#{k.upcase.gsub('_', ' ')}\n#{v}" }.join("\n\n")

    {
      "narrative_sections"   => sections,
      "full_narrative"       => full,
      "subject_name"         => name,
      "activity_type"        => typology,
      "filing_recommendation" => filing
    }
  end

  def self.for_qa(evidence, pattern_analysis, narrative)
    inbound_ev  = evidence.dig("transaction_summary", "total_inbound").to_i
    outbound_ev = evidence.dig("transaction_summary", "total_outbound").to_i
    full_text   = narrative["full_narrative"].to_s.downcase
    sections    = narrative["narrative_sections"] || {}

    checks = [
      { "check_name" => "Transaction Totals Validation",   "passed" => full_text.include?(inbound_ev.to_s[0..4]),        "note" => "Inbound amount referenced in narrative" },
      { "check_name" => "All 5 SAR Sections Present",      "passed" => sections.keys.size == 5,                           "note" => "#{sections.keys.size}/5 sections found" },
      { "check_name" => "Red Flags Referenced",            "passed" => full_text.include?("red flag") || full_text.include?("suspicious"), "note" => "Red flag language present in narrative" },
      { "check_name" => "Regulatory Citation Present",     "passed" => full_text.include?("fincen") || full_text.include?("fatf"),         "note" => "FinCEN or FATF referenced" },
      { "check_name" => "Subject Identified",              "passed" => full_text.include?(evidence.dig("customer_profile", "customer_name").to_s.downcase), "note" => "Subject name appears in narrative" },
      { "check_name" => "Money Laundering Stage Noted",    "passed" => full_text.include?("layering") || full_text.include?("placement") || full_text.include?("integration"), "note" => "ML stage referenced" },
      { "check_name" => "Filing Recommendation Present",   "passed" => narrative["filing_recommendation"].present?,       "note" => narrative["filing_recommendation"].to_s },
      { "check_name" => "Pass-Through Analysis Included",  "passed" => full_text.include?("pass-through") || full_text.include?("conduit"), "note" => "Pass-through language found" }
    ]

    passed_count = checks.count { |c| c["passed"] }
    score = ((passed_count.to_f / checks.size) * 100).round

    {
      "validation_passed" => score >= 75,
      "score"             => score,
      "checks"            => checks,
      "critical_issues"   => score < 75 ? ["Narrative may be missing key SAR elements"] : [],
      "suggestions"       => ["Consider adding specific transaction IDs to the activity overview", "Ensure counterparty names are referenced where available"],
      "qa_summary"        => "Automated QA completed. #{passed_count}/#{checks.size} checks passed. Score: #{score}/100. " \
                             "#{score >= 75 ? 'Narrative meets minimum SAR filing requirements.' : 'Review recommended before filing.'}"
    }
  end
end
