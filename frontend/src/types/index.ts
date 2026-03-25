// ─── AML Alert Types ──────────────────────────────────────────────────────────

export interface CustomerProfile {
  customer_id: string;
  customer_name: string;
  business_type: string;
  account_open_date: string;
  expected_monthly_turnover: number;
  risk_rating: "Low" | "Medium" | "High" | "Critical";
}

export interface Transaction {
  txn_id: string;
  date: string;
  type: string;
  amount: number;
  originator?: string;
  beneficiary?: string;
  country?: string;
  branch?: string;
}

export interface AlertSummary {
  alert_id: string;
  alert_type: string;
  alert_generated_date: string;
  severity: "Low" | "Medium" | "High" | "Critical";
  customer_name: string;
  risk_rating: string;
  total_inbound: number;
  total_outbound: number;
}

export interface Alert extends AlertSummary {
  customer_profile: CustomerProfile;
  kyc: {
    id_verified: boolean;
    beneficial_owner_disclosed: boolean;
    last_kyc_review: string;
    pep_status: boolean;
    sanctions_match: boolean;
  };
  transactions: Transaction[];
  prior_sars: Array<{ sar_id: string; filed_date: string; reason: string }>;
}

// ─── Agent Output Types ───────────────────────────────────────────────────────

export interface Evidence {
  customer_profile: CustomerProfile;
  kyc_summary: {
    verified: boolean;
    pep: boolean;
    sanctions: boolean;
    last_review: string;
    beneficial_owner_disclosed: boolean;
  };
  transaction_summary: {
    total_inbound: number;
    total_outbound: number;
    transaction_count: number;
    date_range: { from: string; to: string };
    high_risk_jurisdictions: string[];
    transactions: Transaction[];
  };
  prior_sar_history: Array<{ sar_id: string; filed_date: string; reason: string }>;
  alert_metadata: {
    alert_id: string;
    alert_type: string;
    severity: string;
    generated_date: string;
  };
}

export interface DetectedPattern {
  rule: string;
  triggered: boolean;
  evidence: string;
  severity: "Low" | "Medium" | "High" | "Critical";
}

export interface PatternAnalysis {
  detected_patterns: DetectedPattern[];
  active_flags: string[];
  confidence_score: number;
  overall_risk_level: "Low" | "Medium" | "High" | "Critical";
  analyst_notes: string;
}

export interface RedFlag {
  flag_name: string;
  regulatory_source: "FinCEN" | "FATF";
  category: string;
  mapped_from_pattern: string;
  description: string;
  risk_weight: "Low" | "Medium" | "High";
}

export interface RedFlagMapping {
  regulatory_red_flags: RedFlag[];
  money_laundering_stage: "Placement" | "Layering" | "Integration" | "Unknown";
  primary_typology: string;
  recommended_action: "File SAR" | "Monitor" | "Close Account" | "Escalate";
}

export interface NarrativeSections {
  customer_background: string;
  activity_overview: string;
  suspicious_behavior: string;
  regulatory_indicators: string;
  investigation_conclusion: string;
}

export interface Narrative {
  narrative_sections: NarrativeSections;
  full_narrative: string;
  subject_name: string;
  activity_type: string;
  filing_recommendation: "File SAR" | "Monitor" | "No Action";
}

export interface QaCheck {
  check_name: string;
  passed: boolean;
  note: string;
}

export interface QaResult {
  validation_passed: boolean;
  score: number;
  checks: QaCheck[];
  critical_issues: string[];
  suggestions: string[];
  qa_summary: string;
}

export interface SarOutput {
  sar_version: string;
  generated_at: string;
  alert_id: string;
  subject: {
    name: string;
    customer_id: string;
    business_type: string;
    risk_rating: string;
  };
  activity_type: string;
  filing_recommendation: string;
  red_flags: string[];
  money_laundering_stage: string;
  primary_typology: string;
  confidence_score: number;
  overall_risk_level: string;
  qa_score: number;
  qa_passed: boolean;
  narrative_sections: NarrativeSections;
  full_narrative: string;
  transaction_summary: {
    total_inbound: number;
    total_outbound: number;
    transaction_count: number;
    date_range: { from: string; to: string };
  };
}

// ─── Investigation Types ──────────────────────────────────────────────────────

export type InvestigationStatus = "pending" | "running" | "completed" | "failed";

export interface Investigation {
  id: number;
  alert_id: string;
  status: InvestigationStatus;
  error_message?: string;
  approved: boolean;
  approved_by?: string;
  approved_at?: string;
  created_at: string;
  updated_at: string;
  alert_data?: Alert;
  evidence?: Evidence;
  pattern_analysis?: PatternAnalysis;
  red_flag_mapping?: RedFlagMapping;
  narrative?: Narrative;
  qa_result?: QaResult;
  sar_output?: SarOutput;
}
