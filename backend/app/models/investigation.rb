class Investigation < ApplicationRecord
  # ── Status lifecycle ──────────────────────────────────────────────────────
  # pending → running → narrative_ready → narrative_approved → sar_ready → sar_approved
  #                                     ↘ closed (narrative rejected / no suspicious patterns)
  #                                                            ↘ sar_ready (revise loop)
  STATUSES = %w[pending running narrative_ready narrative_approved sar_ready sar_approved closed failed].freeze

  validates :alert_id, presence: true
  validates :status,   inclusion: { in: STATUSES }

  # ── JSON column helpers ───────────────────────────────────────────────────
  %w[alert_data evidence pattern_analysis red_flag_mapping narrative qa_result sar_output].each do |col|
    define_method("#{col}_parsed") do
      raw = send(col)
      raw.present? ? JSON.parse(raw) : nil
    end
  end

  # ── Status helpers ────────────────────────────────────────────────────────
  def narrative_approved?
    narrative_approved_at.present?
  end

  def sar_approved?
    sar_approved_at.present?
  end

  def closed?
    status == "closed"
  end

  # ── Transition helpers ────────────────────────────────────────────────────
  def running!
    update!(status: "running")
  end

  def narrative_ready!(outputs = {})
    update!(outputs.merge(status: "narrative_ready"))
  end

  def approve_narrative!(by: "Investigator")
    update!(status: "narrative_approved", narrative_approved_at: Time.current, narrative_approved_by: by)
  end

  def close!(reason = "Narrative not approved")
    update!(status: "closed", error_message: reason)
  end

  def sar_ready!(sar_output:)
    update!(status: "sar_ready", sar_output: sar_output)
  end

  def approve_sar!(by: "Lead Investigator")
    update!(status: "sar_approved", sar_approved_at: Time.current, sar_approved_by: by)
  end

  def failed!(message)
    update!(status: "failed", error_message: message)
  end

  def increment_regeneration!
    increment!(:regeneration_count)
  end
end
