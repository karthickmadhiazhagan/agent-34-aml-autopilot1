// ─── AML Alert Types (DB-backed) ──────────────────────────────────────────────

export interface CustomerInfo {
  id: string;
  name: string;
  email: string;
  phone: string;
  nationality: string;
  country_of_residence: string;
  occupation: string;
  date_of_birth: string | null;
  risk_score: number;
  risk_label: string;
  kyc_status: string;   // verified | pending | failed | enhanced_due_diligence
  is_pep: boolean;
}

export interface AccountInfo {
  account_number: string;
  type: string;         // checking | savings | business | offshore
  balance: number;
  currency: string;
  status: string;       // active | frozen | closed | dormant
  branch: string;
  opened_at: string | null;
}

export interface Transaction {
  id: string;
  type: string;
  amount: number;
  currency: string;
  from_account: string | null;
  to_account: string | null;
  description: string;
  date: string;
  location: string | null;
  counterparty_name: string | null;
  counterparty_country: string | null;
  status: string;
}

export interface AlertMetadata {
  total_amount: number;
  transaction_count: number;
  time_period: string;
  rule_triggered: string;
  risk_indicators: string[];
  [key: string]: unknown;
}

export interface AlertSummary {
  alert_id: string;
  alert_type: string;
  severity: string;
  status: string;
  customer: { id: string; name: string; risk_score: number };
  account: { account_number: string; type: string };
  description: string;
  total_amount: number;
  transaction_count: number;
  created_at: string;
}

export interface Alert {
  alert_id: string;
  alert_type: string;
  severity: string;
  status: string;
  customer: CustomerInfo;
  account: AccountInfo;
  transactions: Transaction[];
  flagged_transactions: Transaction[];
  metadata: AlertMetadata;
}

// ─── Agent Output Types ───────────────────────────────────────────────────────

export interface Evidence {
  customer_profile: {
    customer_id: string;
    customer_name: string;
    business_type: string;
    risk_rating: string;
  };
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
    account_open_date?: string;
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

export type InvestigationStatus =
  | "pending" | "running"
  | "narrative_ready" | "narrative_approved"
  | "sar_ready" | "sar_approved"
  | "closed" | "failed";

export interface Investigation {
  id: number;
  alert_id: string;
  status: InvestigationStatus;
  ai_provider: "claude" | "gemini";
  error_message?: string;
  regeneration_count: number;
  narrative_approved: boolean;
  narrative_approved_by?: string;
  narrative_approved_at?: string;
  sar_approved: boolean;
  sar_approved_by?: string;
  sar_approved_at?: string;
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
