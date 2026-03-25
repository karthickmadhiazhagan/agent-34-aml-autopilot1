require "prawn"
require "prawn/table"

# SarPdfGenerator – Produces a professional SAR PDF from an approved investigation.
class SarPdfGenerator
  DARK_BLUE   = "1a2744"
  MID_BLUE    = "2563eb"
  LIGHT_BLUE  = "dbeafe"
  RED         = "dc2626"
  GRAY_BORDER = "e2e8f0"
  TEXT_DARK   = "1e293b"
  TEXT_MID    = "475569"
  TEXT_LIGHT  = "94a3b8"
  WHITE       = "ffffff"

  def initialize(investigation)
    @inv      = investigation
    @sar      = investigation.sar_output_parsed || {}
    @narrative = investigation.narrative_parsed || {}
    @patterns  = investigation.pattern_analysis_parsed || {}
    @red_flags = investigation.red_flag_mapping_parsed || {}
  end

  def generate
    Prawn::Document.new(
      page_size: "A4",
      margin:    [40, 50, 40, 50],
      info: {
        Title:   "SAR – #{@sar.dig('subject', 'name')}",
        Author:  "Agent 34 – AML Case Autopilot",
        Subject: "Suspicious Activity Report"
      }
    ) do |pdf|
      # Store available width once so all methods use the same value
      @w = pdf.bounds.width

      cover_header(pdf)
      subject_section(pdf)
      activity_summary(pdf)
      transaction_table(pdf)
      red_flags_section(pdf)
      narrative_sections(pdf)
      qa_section(pdf)
      approval_footer(pdf)
      page_numbers(pdf)
    end.render
  end

  private

  # ── Cover Header ─────────────────────────────────────────────────────────
  def cover_header(pdf)
    pdf.fill_color DARK_BLUE
    pdf.fill_rectangle [pdf.bounds.left, pdf.bounds.top + 20], @w, 90
    pdf.fill_color WHITE
    pdf.text_box s("SUSPICIOUS ACTIVITY REPORT"),
      at: [10, pdf.bounds.top + 10], width: @w - 20, size: 18, style: :bold, align: :center
    pdf.text_box s("Agent 34 - AML Case Narrative & Evidence Autopilot"),
      at: [10, pdf.bounds.top - 18], width: @w - 20, size: 9, align: :center, color: "93c5fd"
    pdf.text_box s("CONFIDENTIAL - FOR REGULATORY USE ONLY"),
      at: [10, pdf.bounds.top - 34], width: @w - 20, size: 8, align: :center, color: "fca5a5"

    rec       = @sar["filing_recommendation"] || "File SAR"
    rec_color = rec == "File SAR" ? RED : "16a34a"
    pdf.fill_color rec_color
    pdf.fill_rounded_rectangle [@w / 2 - 60, pdf.bounds.top - 55], 120, 22, 4
    pdf.fill_color WHITE
    pdf.text_box s(rec.upcase),
      at: [@w / 2 - 55, pdf.bounds.top - 59], width: 110, size: 10, style: :bold, align: :center
    pdf.fill_color TEXT_DARK
    pdf.move_down 80
    hr(pdf)
    pdf.move_down 12
  end

  # ── Subject Section ───────────────────────────────────────────────────────
  def subject_section(pdf)
    section_title(pdf, "I. SUBJECT OF REPORT")

    subject   = @sar["subject"] || {}
    generated = @sar["generated_at"] ? Time.parse(@sar["generated_at"]).strftime("%B %d, %Y") : Date.today.strftime("%B %d, %Y")

    # Split available width: label 22%, value 28%, label 22%, value 28%
    c0 = (@w * 0.22).floor
    c1 = (@w * 0.28).floor
    c2 = (@w * 0.22).floor
    c3 = @w - c0 - c1 - c2   # remainder ensures exact sum

    rows = [
      [s("Subject Name"),   s(subject["name"]),           s("Customer ID"),   s(subject["customer_id"])],
      [s("Business Type"),  s(subject["business_type"]),   s("Risk Rating"),   s(subject["risk_rating"])],
      [s("Account Opened"), s(subject["account_open_date"]),s("Alert ID"),     s(@sar["alert_id"] || @inv.alert_id)],
      [s("Activity Type"),  s(@sar["activity_type"]),      s("Report Date"),   s(generated)]
    ]
    kv_table(pdf, rows, [c0, c1, c2, c3])
    pdf.move_down 16
  end

  # ── Activity Summary ─────────────────────────────────────────────────────
  def activity_summary(pdf)
    section_title(pdf, "II. ACTIVITY SUMMARY")

    txn      = @sar["transaction_summary"] || {}
    inbound  = fmt_currency(txn["total_inbound"].to_f)
    outbound = fmt_currency(txn["total_outbound"].to_f)
    ratio    = txn["total_inbound"].to_f > 0 ? (txn["total_outbound"].to_f / txn["total_inbound"].to_f * 100).round(1) : 0
    risk     = @sar["overall_risk_level"] || "—"

    boxes = [
      [s(inbound),      s("Total Inbound"),      "006d2c"],
      [s(outbound),     s("Total Outbound"),      "9b1c1c"],
      [s("#{ratio}%"),  s("Pass-Through Ratio"),  ratio >= 90 ? RED : "b45309"],
      [s(risk),         s("Overall Risk Level"),  risk == "Critical" ? RED : (risk == "High" ? "c2410c" : "1d4ed8")]
    ]
    box_w = ((@w - 9) / 4).floor
    boxes.each_with_index do |(val, label, color), i|
      x = i * (box_w + 3)
      pdf.fill_color "f1f5f9"
      pdf.fill_rectangle [x, pdf.cursor], box_w, 46
      pdf.fill_color color
      pdf.text_box val,   at: [x + 6, pdf.cursor - 6],  width: box_w - 12, size: 13, style: :bold
      pdf.fill_color TEXT_MID
      pdf.text_box label, at: [x + 6, pdf.cursor - 26], width: box_w - 12, size: 7
    end
    pdf.move_down 52

    from    = txn.dig("date_range", "from") || "—"
    to_date = txn.dig("date_range", "to")   || "—"
    stage   = @sar["money_laundering_stage"] || "—"
    typo    = @sar["primary_typology"]       || "—"
    conf    = "#{((@sar["confidence_score"].to_f) * 100).round(0)}%"

    c0 = (@w * 0.22).floor; c1 = (@w * 0.28).floor; c2 = (@w * 0.22).floor; c3 = @w - c0 - c1 - c2
    kv_table(pdf, [
      [s("Period"),   s("#{from} - #{to_date}"), s("ML Stage"),   s(stage)],
      [s("Typology"), s(typo),                   s("Confidence"), s(conf)]
    ], [c0, c1, c2, c3])

    hj = @sar.dig("transaction_summary", "high_risk_jurisdictions") || []
    if hj.any?
      pdf.move_down 6
      pdf.fill_color TEXT_MID
      pdf.formatted_text [
        { text: s("High-Risk Jurisdictions: "), styles: [:bold], size: 8, color: TEXT_MID },
        { text: s(hj.join("  /  ")),            size: 8,         color: RED }
      ]
    end
    pdf.fill_color TEXT_DARK
    pdf.move_down 16
  end

  # ── Transaction Table ─────────────────────────────────────────────────────
  def transaction_table(pdf)
    evidence = @inv.evidence_parsed || {}
    txns     = evidence.dig("transaction_summary", "transactions") || []
    return if txns.empty?

    section_title(pdf, "III. TRANSACTION HISTORY")

    # Column widths summing to @w
    cws = [(@w*0.12).floor, (@w*0.12).floor, (@w*0.16).floor,
           (@w*0.14).floor, (@w*0.32).floor, @w - (@w*0.12).floor*2 - (@w*0.16).floor - (@w*0.14).floor - (@w*0.32).floor]

    header = [["Txn ID", "Date", "Type", "Amount", "Counterparty", "Country"]]
    rows   = txns.map do |t|
      cpty = (t["originator"] || t["beneficiary"] || t["branch"] || "-").to_s[0..30]
      [s(t["txn_id"]), s(t["date"]), s(t["type"]),
       s(fmt_currency(t["amount"].to_f)), s(cpty), s(t["country"] || "US")]
    end

    pdf.table(header + rows,
      column_widths: cws,
      header: true,
      cell_style: { size: 8, padding: [4, 4], border_color: GRAY_BORDER, borders: [:bottom] }
    ) do
      row(0).background_color = DARK_BLUE
      row(0).text_color       = WHITE
      row(0).font_style       = :bold
      column(3).align         = :right
    end
    pdf.move_down 16
  end

  # ── Red Flags ─────────────────────────────────────────────────────────────
  def red_flags_section(pdf)
    flags = @sar["regulatory_red_flags"] || []
    return if flags.empty?

    section_title(pdf, "IV. REGULATORY RED FLAGS")

    flags.each do |flag|
      src_color = flag["regulatory_source"] == "FinCEN" ? RED : MID_BLUE
      pdf.fill_color src_color
      pdf.fill_rounded_rectangle [0, pdf.cursor + 3], 52, 14, 3
      pdf.fill_color WHITE
      pdf.text_box s(flag["regulatory_source"]),
        at: [2, pdf.cursor + 1], width: 48, size: 7, style: :bold, align: :center
      pdf.fill_color TEXT_DARK
      pdf.text_box s(flag["flag_name"]),
        at: [58, pdf.cursor + 1], width: @w - 60, size: 9, style: :bold
      pdf.move_down 6
      pdf.fill_color TEXT_MID
      pdf.text s(flag["description"]), size: 8, indent_paragraphs: 58
      pdf.fill_color TEXT_DARK
      pdf.move_down 8
    end
    pdf.move_down 4
  end

  # ── Narrative Sections ────────────────────────────────────────────────────
  def narrative_sections(pdf)
    sections = @sar["narrative_sections"] || {}
    return if sections.empty?

    section_title(pdf, "V. INVESTIGATION NARRATIVE")

    labels = {
      "customer_background"      => "Customer Background",
      "activity_overview"        => "Activity Overview",
      "suspicious_behavior"      => "Suspicious Behavior",
      "regulatory_indicators"    => "Regulatory Indicators",
      "investigation_conclusion" => "Investigation Conclusion"
    }

    sections.each do |key, text|
      pdf.move_down 4
      pdf.fill_color MID_BLUE
      pdf.text s(labels[key] || key.gsub("_", " ").capitalize), size: 10, style: :bold
      pdf.fill_color TEXT_DARK
      pdf.move_down 3
      pdf.text s(text), size: 9, leading: 3
      pdf.move_down 8
    end
  end

  # ── QA Section ────────────────────────────────────────────────────────────
  def qa_section(pdf)
    qa = @inv.qa_result_parsed
    return unless qa

    hr(pdf)
    pdf.move_down 8
    score  = qa["score"].to_i
    passed = qa["validation_passed"]
    color  = passed ? "166534" : "b45309"
    pdf.fill_color color
    pdf.text s("QA Validation Score: #{score}/100  -  #{passed ? 'PASSED' : 'REVIEW RECOMMENDED'}"),
      size: 9, style: :bold
    pdf.fill_color TEXT_MID
    pdf.text s(qa["qa_summary"]), size: 8, leading: 2
    pdf.move_down 8
  end

  # ── Approval Footer ───────────────────────────────────────────────────────
  def approval_footer(pdf)
    hr(pdf)
    pdf.move_down 8
    pdf.fill_color DARK_BLUE
    pdf.text "APPROVAL RECORD", size: 9, style: :bold
    pdf.move_down 6

    c0 = (@w * 0.26).floor; c1 = (@w * 0.38).floor
    c2 = (@w * 0.12).floor; c3 = @w - c0 - c1 - c2

    kv_table(pdf, [
      [s("Narrative Approved By"), s(@inv.narrative_approved_by),
       s("Date"), s(@inv.narrative_approved_at ? @inv.narrative_approved_at.strftime("%b %d, %Y %H:%M UTC") : "-")],
      [s("SAR Approved By"), s(@inv.sar_approved_by),
       s("Date"), s(@inv.sar_approved_at ? @inv.sar_approved_at.strftime("%b %d, %Y %H:%M UTC") : "Pending")]
    ], [c0, c1, c2, c3])

    pdf.move_down 12
    pdf.fill_color TEXT_LIGHT
    pdf.text s("Generated by Agent 34 - AML Case Autopilot | Alert #{@inv.alert_id} | " \
               "Investigation ##{@inv.id} | #{Time.current.strftime('%Y-%m-%d %H:%M UTC')}"),
      size: 7, align: :center
  end

  # ── Page Numbers ──────────────────────────────────────────────────────────
  def page_numbers(pdf)
    pdf.number_pages "Page <page> of <total>",
      at: [pdf.bounds.right - 90, 0], width: 90,
      size: 7, color: TEXT_LIGHT, align: :right
  end

  # ── Helpers ───────────────────────────────────────────────────────────────

  # Render a 4-column key-value table with exact column widths.
  def kv_table(pdf, rows, col_widths)
    pdf.table(rows,
      column_widths: col_widths,
      cell_style: { borders: [:bottom], border_color: GRAY_BORDER, padding: [6, 4], size: 9 }
    ) do
      column(0).font_style = :bold
      column(0).text_color = TEXT_MID
      column(2).font_style = :bold
      column(2).text_color = TEXT_MID
    end
  end

  def section_title(pdf, title)
    pdf.fill_color LIGHT_BLUE
    pdf.fill_rectangle [0, pdf.cursor + 4], @w, 20
    pdf.fill_color DARK_BLUE
    pdf.text_box s(title), at: [6, pdf.cursor + 1], width: @w - 12, size: 9, style: :bold
    pdf.move_down 22
    pdf.fill_color TEXT_DARK
  end

  def hr(pdf)
    pdf.fill_color GRAY_BORDER
    pdf.fill_rectangle [0, pdf.cursor + 1], @w, 1
    pdf.fill_color TEXT_DARK
  end

  def fmt_currency(amount)
    "$#{amount.to_i.to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
  end

  # Sanitize a string to Windows-1252 safe characters.
  # Prawn's built-in fonts don't support UTF-8, so we replace common
  # Unicode characters with ASCII equivalents before rendering.
  def s(text)
    return "" if text.nil?
    text.to_s
      .gsub("\u2014", "-")   # em dash  —
      .gsub("\u2013", "-")   # en dash  –
      .gsub("\u2012", "-")   # figure dash
      .gsub("\u201C", '"')   # left double quote  "
      .gsub("\u201D", '"')   # right double quote "
      .gsub("\u2018", "'")   # left single quote  '
      .gsub("\u2019", "'")   # right single quote '
      .gsub("\u2026", "...") # ellipsis  …
      .gsub("\u2022", "*")   # bullet    •
      .gsub("\u2713", "[OK]")# checkmark ✓
      .gsub("\u2717", "[X]") # cross     ✗
      .gsub("\u26A0", "[!]") # warning   ⚠
      .gsub("\u00A0", " ")   # non-breaking space
      .gsub("\u00B7", "·")   # middle dot (already latin-1)
      .encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?")
      .encode("UTF-8")
  end
end
