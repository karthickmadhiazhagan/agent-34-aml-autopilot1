"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { fetchInvestigation, formatCurrency, severityColor, statusColor, statusLabel } from "@/lib/api";
import type { Investigation } from "@/types";
import Link from "next/link";

// Simple step indicator: just a list of numbered labels
function FlowSteps({ inv }: { inv: Investigation }) {
  const steps = [
    { label: "Evidence",         done: !!inv.evidence },
    { label: "Pattern Analysis", done: !!inv.pattern_analysis },
    { label: "Red Flags",        done: !!inv.red_flag_mapping },
    { label: "Narrative",        done: !!inv.narrative },
    { label: "QA",               done: !!inv.qa_result },
    { label: "Narrative Review", done: ["narrative_approved","sar_ready","sar_approved"].includes(inv.status) },
    { label: "SAR Report",       done: inv.status === "sar_approved" },
  ];
  return (
    <div className="flex gap-2 flex-wrap text-sm">
      {steps.map((s, i) => (
        <span key={s.label} className={`px-2 py-0.5 border text-xs ${s.done ? "border-green-500 text-green-700 bg-green-50" : "border-gray-300 text-gray-400"}`}>
          {i + 1}. {s.label} {s.done ? "✓" : ""}
        </span>
      ))}
    </div>
  );
}

// Simple collapsible section
function AgentSection({ title, status, children }: {
  title: string;
  status: "done" | "pending" | "error";
  children?: React.ReactNode;
}) {
  const [open, setOpen] = useState(false);
  const statusText = status === "done" ? "[Done]" : status === "error" ? "[Error]" : "[Pending]";
  const statusCls  = status === "done" ? "text-green-700" : status === "error" ? "text-red-700" : "text-gray-400";

  return (
    <div className="border border-gray-300 mb-2">
      <button
        onClick={() => status === "done" && children && setOpen(!open)}
        className="w-full text-left px-3 py-2 flex items-center justify-between hover:bg-gray-50"
      >
        <span className="font-medium text-sm">{title}</span>
        <span className={`text-xs ${statusCls}`}>{statusText} {status === "done" && children ? (open ? "▲" : "▼") : ""}</span>
      </button>
      {open && children && (
        <div className="px-3 pb-3 pt-2 border-t border-gray-200 text-sm">{children}</div>
      )}
    </div>
  );
}

export default function InvestigationPage() {
  const { id } = useParams<{ id: string }>();
  const [inv, setInv] = useState<Investigation | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchInvestigation(Number(id))
      .then(setInv)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [id]);

  useEffect(() => {
    if (!inv) return;
    if (!["pending", "running", "narrative_approved"].includes(inv.status)) return;
    const timer = setInterval(() => {
      fetchInvestigation(Number(id)).then(setInv).catch(console.error);
    }, 3000);
    return () => clearInterval(timer);
  }, [id, inv?.status]);

  if (loading) return <p className="text-gray-500">Loading investigation…</p>;
  if (!inv) return <div className="border border-red-400 p-3 text-red-700 text-sm">{error || "Not found"}</div>;

  return (
    <div>
      <Link href={`/alerts/${inv.alert_id}`} className="text-blue-600 hover:underline text-sm">
        &larr; Back to Alert
      </Link>

      {/* Header */}
      <div className="mt-4 mb-4 flex items-start justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1 flex-wrap text-sm">
            <span className={`badge ${statusColor(inv.status)}`}>{statusLabel(inv.status)}</span>
            <span className="text-gray-400">Investigation #{inv.id} · {inv.alert_id}</span>
            <span className="text-gray-500">AI: {inv.ai_provider === "gemini" ? "Gemini Flash" : "Claude"}</span>
            {inv.regeneration_count > 0 && (
              <span className="text-gray-500">Regenerated ×{inv.regeneration_count}</span>
            )}
          </div>
          <h1 className="text-xl font-bold">
            {inv.alert_data?.customer_profile?.customer_name || inv.alert_id}
          </h1>
          <p className="text-gray-500 text-sm">{inv.alert_data?.alert_type}</p>
        </div>

        <div className="shrink-0">
          {inv.status === "narrative_ready" && (
            <Link href={`/investigations/${inv.id}/narrative`} className="btn-primary">Review Narrative &rarr;</Link>
          )}
          {inv.status === "sar_ready" && (
            <Link href={`/investigations/${inv.id}/sar`} className="btn-primary">Review SAR &rarr;</Link>
          )}
          {inv.status === "sar_approved" && (
            <Link href={`/investigations/${inv.id}/sar`} className="btn-primary">View Approved SAR</Link>
          )}
        </div>
      </div>

      {/* Flow Steps */}
      <div className="border border-gray-200 p-3 mb-4">
        <p className="text-xs text-gray-500 mb-2 font-semibold uppercase">Investigation Flow</p>
        <FlowSteps inv={inv} />
      </div>

      {/* Live progress while running */}
      {(inv.status === "pending" || inv.status === "running") && (
        <div className="border border-blue-300 bg-blue-50 p-3 mb-4 text-sm">
          <p className="font-semibold text-blue-800 mb-2">
            {inv.ai_provider === "gemini" ? "Gemini Flash" : "Claude"} is analyzing this alert… (auto-refreshes every 3s)
          </p>
          <ul className="space-y-1">
            {[
              { key: "evidence",         label: "Evidence Collection",  done: !!inv.evidence },
              { key: "pattern_analysis", label: "Pattern Analysis",     done: !!inv.pattern_analysis },
              { key: "red_flag_mapping", label: "Red Flag Mapping",     done: !!inv.red_flag_mapping },
              { key: "narrative",        label: "Narrative Generation", done: !!inv.narrative },
              { key: "qa_result",        label: "QA Validation",        done: !!inv.qa_result },
            ].map(({ key, label, done }) => (
              <li key={key} className={done ? "text-green-700" : "text-blue-600"}>
                {done ? "✓" : "○"} {label}
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Error / Closed */}
      {inv.status === "failed" && (
        <div className="border border-red-400 bg-red-50 text-red-700 p-3 text-sm mb-4">
          <p className="font-semibold mb-1">Investigation failed</p>
          <p className="font-mono text-xs bg-red-100 p-2">{inv.error_message}</p>
          {(inv.error_message?.includes("429") || inv.error_message?.includes("rate limit")) && (
            <div className="mt-2 text-xs">
              <p className="font-semibold">Rate limit hit — wait 60 seconds then retry with Claude instead of Gemini,
              or set <code>MOCK_AI=true</code> in .env to bypass the API.</p>
              <Link href={`/alerts/${inv.alert_id}`} className="text-blue-600 hover:underline mt-1 inline-block">
                &larr; Go back and retry
              </Link>
            </div>
          )}
        </div>
      )}
      {inv.status === "closed" && (
        <div className="border border-gray-300 bg-gray-50 text-gray-600 p-3 text-sm mb-4">
          <p className="font-semibold">Investigation Closed / Monitor</p>
          <p>{inv.error_message}</p>
        </div>
      )}

      {/* Summary stats */}
      {inv.pattern_analysis && (
        <div className="text-sm border border-gray-200 p-3 flex gap-6 mb-4">
          <span>Inbound: <strong className="text-green-700">{formatCurrency(inv.evidence?.transaction_summary.total_inbound || 0)}</strong></span>
          <span>Outbound: <strong className="text-red-700">{formatCurrency(inv.evidence?.transaction_summary.total_outbound || 0)}</strong></span>
          <span>Risk Level: <strong>{inv.pattern_analysis.overall_risk_level}</strong></span>
          <span>AI Confidence: <strong>{Math.round((inv.pattern_analysis.confidence_score || 0) * 100)}%</strong></span>
        </div>
      )}

      {/* Agent Pipeline */}
      <p className="text-xs font-semibold text-gray-500 uppercase mb-2">AI Agent Pipeline</p>

      {/* Agent 1 – Evidence */}
      <AgentSection title="1. Evidence Collection Agent"
        status={inv.evidence ? "done" : inv.status === "failed" ? "error" : "pending"}>
        {inv.evidence && (
          <table className="w-full border-collapse text-sm">
            <tbody>
              {[
                ["Customer",           inv.evidence.customer_profile?.customer_name],
                ["Business Type",      inv.evidence.customer_profile?.business_type],
                ["Risk Rating",        inv.evidence.customer_profile?.risk_rating],
                ["Transactions",       inv.evidence.transaction_summary?.transaction_count],
                ["PEP Status",         inv.evidence.kyc_summary?.pep ? "PEP" : "Clear"],
                ["Beneficial Owner",   inv.evidence.kyc_summary?.beneficial_owner_disclosed ? "Disclosed" : "Not Disclosed"],
                ["High-Risk Jurisdictions", inv.evidence.transaction_summary?.high_risk_jurisdictions?.join(", ") || "None"],
                ["Prior SARs",         inv.evidence.prior_sar_history?.length || 0],
              ].map(([k, v]) => (
                <tr key={String(k)} className="border-b border-gray-100">
                  <td className="py-1 pr-4 text-gray-500 w-1/2">{k}</td>
                  <td className="py-1 font-medium">{String(v)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </AgentSection>

      {/* Agent 2 – Pattern */}
      <AgentSection title="2. Pattern Analysis Agent"
        status={inv.pattern_analysis ? "done" : inv.status === "failed" ? "error" : "pending"}>
        {inv.pattern_analysis && (
          <div>
            <p className="mb-2">
              <span className={`badge ${severityColor(inv.pattern_analysis.overall_risk_level)}`}>
                {inv.pattern_analysis.overall_risk_level} Risk
              </span>
              {" "}Confidence: <strong>{Math.round((inv.pattern_analysis.confidence_score || 0) * 100)}%</strong>
            </p>
            <table className="w-full border-collapse text-sm">
              <thead className="bg-gray-100">
                <tr>
                  <th className="border border-gray-200 px-2 py-1 text-left">Pattern</th>
                  <th className="border border-gray-200 px-2 py-1 text-left">Triggered?</th>
                  <th className="border border-gray-200 px-2 py-1 text-left">Evidence</th>
                </tr>
              </thead>
              <tbody>
                {inv.pattern_analysis.detected_patterns?.map(p => (
                  <tr key={p.rule} className="border-b border-gray-100">
                    <td className="border border-gray-200 px-2 py-1">{p.rule}</td>
                    <td className={`border border-gray-200 px-2 py-1 ${p.triggered ? "text-red-700 font-bold" : "text-gray-400"}`}>
                      {p.triggered ? "Yes" : "No"}
                    </td>
                    <td className="border border-gray-200 px-2 py-1 text-gray-600">{p.evidence}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {inv.pattern_analysis.analyst_notes && (
              <p className="text-gray-500 text-xs mt-2 italic">{inv.pattern_analysis.analyst_notes}</p>
            )}
          </div>
        )}
      </AgentSection>

      {/* Agent 3 – Red Flags */}
      <AgentSection title="3. Red Flag Mapping Agent"
        status={inv.red_flag_mapping ? "done" : inv.status === "failed" ? "error" : "pending"}>
        {inv.red_flag_mapping && (
          <div>
            <p className="mb-2 text-sm">
              Stage: <strong>{inv.red_flag_mapping.money_laundering_stage}</strong> &nbsp;|&nbsp;
              Typology: <strong>{inv.red_flag_mapping.primary_typology}</strong> &nbsp;|&nbsp;
              Action: <strong>{inv.red_flag_mapping.recommended_action}</strong>
            </p>
            <table className="w-full border-collapse text-sm">
              <thead className="bg-gray-100">
                <tr>
                  <th className="border border-gray-200 px-2 py-1 text-left">Flag</th>
                  <th className="border border-gray-200 px-2 py-1 text-left">Source</th>
                  <th className="border border-gray-200 px-2 py-1 text-left">Description</th>
                </tr>
              </thead>
              <tbody>
                {inv.red_flag_mapping.regulatory_red_flags?.map(f => (
                  <tr key={f.flag_name} className="border-b border-gray-100">
                    <td className="border border-gray-200 px-2 py-1 font-medium">{f.flag_name}</td>
                    <td className="border border-gray-200 px-2 py-1 text-gray-500">{f.regulatory_source}</td>
                    <td className="border border-gray-200 px-2 py-1 text-gray-600">{f.description}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </AgentSection>

      {/* Agent 4 – Narrative */}
      <AgentSection title="4. Narrative Generation Agent"
        status={inv.narrative ? "done" : inv.status === "failed" ? "error" : "pending"}>
        {inv.narrative && (
          <div>
            <p className="mb-2 text-sm">
              Recommendation: <strong>{inv.narrative.filing_recommendation}</strong>
              {inv.narrative_approved && <span className="ml-3 text-green-700">✓ Approved by {inv.narrative_approved_by}</span>}
            </p>
            <div className="border border-gray-200 p-3 bg-gray-50 text-sm">
              <p className="font-semibold mb-1 text-gray-500 text-xs uppercase">Activity Overview</p>
              <p>{inv.narrative.narrative_sections?.activity_overview}</p>
            </div>
            <Link href={`/investigations/${inv.id}/narrative`} className="text-blue-600 hover:underline text-sm mt-2 inline-block">
              Read full narrative &rarr;
            </Link>
          </div>
        )}
      </AgentSection>

      {/* Agent 5 – QA */}
      <AgentSection title="5. QA Validation Agent"
        status={inv.qa_result ? "done" : inv.status === "failed" ? "error" : "pending"}>
        {inv.qa_result && (
          <div>
            <p className="mb-2 text-sm">
              Score: <strong>{inv.qa_result.score}/100</strong> &nbsp;
              {inv.qa_result.validation_passed ? "✓ Passed" : "⚠ Review Recommended"}
            </p>
            <p className="text-gray-500 text-xs mb-2">{inv.qa_result.qa_summary}</p>
            <table className="w-full border-collapse text-sm">
              <tbody>
                {inv.qa_result.checks?.map(c => (
                  <tr key={c.check_name} className="border-b border-gray-100">
                    <td className={`py-1 pr-3 ${c.passed ? "text-green-700" : "text-red-700"}`}>
                      {c.passed ? "✓" : "✗"} {c.check_name}
                    </td>
                    <td className="py-1 text-gray-500 text-xs">{c.note}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </AgentSection>

      {/* Bottom CTA */}
      {inv.status === "narrative_ready" && (
        <div className="border border-blue-300 bg-blue-50 p-3 mt-4 flex items-center justify-between gap-4">
          <p className="text-sm text-blue-800">Narrative is ready for your review.</p>
          <Link href={`/investigations/${inv.id}/narrative`} className="btn-primary">Review Narrative &rarr;</Link>
        </div>
      )}
      {inv.status === "sar_ready" && (
        <div className="border border-yellow-400 bg-yellow-50 p-3 mt-4 flex items-center justify-between gap-4">
          <p className="text-sm text-yellow-800">SAR is ready for final approval.</p>
          <Link href={`/investigations/${inv.id}/sar`} className="btn-primary">Review SAR &rarr;</Link>
        </div>
      )}
    </div>
  );
}
