"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import {
  fetchInvestigation, formatCurrency, severityColor,
  statusColor, statusLabel
} from "@/lib/api";
import type { Investigation } from "@/types";
import {
  ArrowLeft, CheckCircle, XCircle, Clock, ChevronDown, ChevronUp,
  FileText, BarChart2, Flag, BookOpen, Shield, ArrowRight
} from "lucide-react";
import Link from "next/link";

// ─── Flow Step ────────────────────────────────────────────────────────────────
function FlowStep({ number, label, active, done, href }: {
  number: number; label: string; active?: boolean; done?: boolean; href?: string;
}) {
  const base = "flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold transition-colors";
  const cls  = done    ? `${base} bg-green-100 text-green-800` :
               active  ? `${base} bg-blue-600 text-white` :
                          `${base} bg-slate-100 text-slate-400`;
  const inner = (
    <span className={cls}>
      <span className={`w-5 h-5 rounded-full flex items-center justify-center text-xs font-bold
        ${done ? "bg-green-500 text-white" : active ? "bg-white text-blue-600" : "bg-slate-200 text-slate-400"}`}>
        {done ? "✓" : number}
      </span>
      {label}
    </span>
  );
  return href && (done || active) ? <Link href={href}>{inner}</Link> : inner;
}

// ─── Agent Card ───────────────────────────────────────────────────────────────
function AgentCard({ icon, title, status, children }: {
  icon: React.ReactNode; title: string;
  status: "done" | "pending" | "error";
  children?: React.ReactNode;
}) {
  const [open, setOpen] = useState(false);
  return (
    <div className={`card overflow-hidden ${status === "error" ? "border-red-200" : ""}`}>
      <button
        onClick={() => children && status === "done" && setOpen(!open)}
        className="w-full flex items-center gap-3 p-4 hover:bg-slate-50 transition-colors text-left"
      >
        <div className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0
          ${status === "done" ? "bg-green-100 text-green-600" :
            status === "error" ? "bg-red-100 text-red-600" : "bg-slate-100 text-slate-400"}`}>
          {status === "done"  ? <CheckCircle className="w-4 h-4" /> :
           status === "error" ? <XCircle className="w-4 h-4" />    :
                                 <Clock className="w-4 h-4" />}
        </div>
        <div className="flex items-center gap-2 flex-1">{icon}<span className="font-medium text-sm">{title}</span></div>
        {children && status === "done" && (
          open ? <ChevronUp className="w-4 h-4 text-slate-400" /> : <ChevronDown className="w-4 h-4 text-slate-400" />
        )}
      </button>
      {open && children && (
        <div className="px-4 pb-5 pt-3 border-t border-slate-100">{children}</div>
      )}
    </div>
  );
}

// ─── Main Page ────────────────────────────────────────────────────────────────
export default function InvestigationPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [inv, setInv] = useState<Investigation | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Initial fetch
  useEffect(() => {
    fetchInvestigation(Number(id))
      .then(setInv)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [id]);

  // Poll every 3 s while pipeline is running
  useEffect(() => {
    if (!inv) return;
    if (!["pending", "running", "narrative_approved"].includes(inv.status)) return;
    const timer = setInterval(() => {
      fetchInvestigation(Number(id))
        .then(setInv)
        .catch(console.error);
    }, 3000);
    return () => clearInterval(timer);
  }, [id, inv?.status]);

  if (loading) return (
    <div className="card p-12 text-center text-slate-400">
      <div className="inline-block w-8 h-8 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin mb-3" />
      <p>Loading investigation…</p>
    </div>
  );

  if (!inv) return <div className="card p-6 text-red-700">{error || "Not found"}</div>;

  const statusDone  = (s: string) => ["narrative_ready","narrative_approved","sar_ready","sar_approved"].includes(inv.status) ||
    (s === "evidence" && inv.evidence) || (s === "pattern" && inv.pattern_analysis) ||
    (s === "redflag" && inv.red_flag_mapping) || (s === "narrative" && inv.narrative) ||
    (s === "qa" && inv.qa_result);

  return (
    <div>
      <Link href={`/alerts/${inv.alert_id}`} className="inline-flex items-center gap-2 text-sm text-slate-500 hover:text-slate-900 mb-6 transition-colors">
        <ArrowLeft className="w-4 h-4" /> Back to Alert
      </Link>

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center gap-2 mb-2 flex-wrap">
            <span className={`badge ${statusColor(inv.status)} text-xs`}>{statusLabel(inv.status)}</span>
            <span className="text-sm text-slate-400">Investigation #{inv.id} · {inv.alert_id}</span>
            {inv.ai_provider === "gemini" ? (
              <span className="inline-flex items-center gap-1 text-xs bg-blue-50 text-blue-700 border border-blue-200 rounded-full px-2 py-0.5">✨ Gemini Flash</span>
            ) : (
              <span className="inline-flex items-center gap-1 text-xs bg-orange-50 text-orange-700 border border-orange-200 rounded-full px-2 py-0.5">🤖 Claude</span>
            )}
            {inv.regeneration_count > 0 && (
              <span className="badge bg-amber-100 text-amber-700 border-amber-200 text-xs">
                Regenerated ×{inv.regeneration_count}
              </span>
            )}
          </div>
          <h1 className="text-2xl font-bold text-slate-900">
            {inv.alert_data?.customer_profile?.customer_name || inv.alert_id}
          </h1>
          <p className="text-slate-500 mt-1">{inv.alert_data?.alert_type}</p>
        </div>

        {/* Phase CTA */}
        {inv.status === "narrative_ready" && (
          <Link href={`/investigations/${inv.id}/narrative`} className="btn-primary shrink-0">
            <BookOpen className="w-4 h-4" />
            Review Narrative
            <ArrowRight className="w-4 h-4" />
          </Link>
        )}
        {inv.status === "sar_ready" && (
          <Link href={`/investigations/${inv.id}/sar`} className="btn-primary shrink-0">
            <FileText className="w-4 h-4" />
            Review SAR
            <ArrowRight className="w-4 h-4" />
          </Link>
        )}
        {inv.status === "sar_approved" && (
          <Link href={`/investigations/${inv.id}/sar`} className="btn-primary shrink-0 bg-green-600 hover:bg-green-700">
            <CheckCircle className="w-4 h-4" />
            View Approved SAR
          </Link>
        )}
      </div>

      {/* Process flowchart progress bar */}
      <div className="card p-4 mb-6">
        <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-3">Investigation Flow</p>
        <div className="flex items-center gap-1 flex-wrap">
          {[
            { n: 1, label: "Evidence", key: "evidence" },
            { n: 2, label: "Patterns", key: "pattern" },
            { n: 3, label: "Red Flags", key: "redflag" },
            { n: 4, label: "Narrative", key: "narrative" },
            { n: 5, label: "QA", key: "qa" },
          ].map(({ n, label, key }, i) => (
            <>
              <FlowStep key={key} number={n} label={label} done={!!{
                evidence: inv.evidence, pattern: inv.pattern_analysis,
                redflag: inv.red_flag_mapping, narrative: inv.narrative, qa: inv.qa_result
              }[key as keyof typeof inv]} />
              {i < 4 && <ArrowRight key={`arr-${i}`} className="w-3 h-3 text-slate-300" />}
            </>
          ))}
          <ArrowRight className="w-3 h-3 text-slate-300" />
          <FlowStep number={6} label="Narrative Review"
            active={inv.status === "narrative_ready"}
            done={["narrative_approved","sar_ready","sar_approved"].includes(inv.status)}
            href={`/investigations/${inv.id}/narrative`} />
          <ArrowRight className="w-3 h-3 text-slate-300" />
          <FlowStep number={7} label="SAR Report"
            active={inv.status === "sar_ready"}
            done={inv.status === "sar_approved"}
            href={`/investigations/${inv.id}/sar`} />
          <ArrowRight className="w-3 h-3 text-slate-300" />
          <FlowStep number={8} label="PDF Export"
            done={inv.status === "sar_approved"}
            href={inv.status === "sar_approved" ? `/investigations/${inv.id}/sar` : undefined} />
        </div>
      </div>

      {/* Live progress banner while pipeline is running */}
      {(inv.status === "pending" || inv.status === "running") && (
        <div className="card p-5 border-blue-200 bg-blue-50 mb-6">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-5 h-5 border-2 border-blue-500 border-t-transparent rounded-full animate-spin shrink-0" />
            <p className="font-semibold text-blue-900">
              {inv.ai_provider === "gemini" ? "✨ Gemini Flash" : "🤖 Claude"} is analyzing this alert…
            </p>
          </div>
          <div className="space-y-1.5 text-sm">
            {[
              { key: "evidence",         label: "Evidence Collection",  done: !!inv.evidence,         ai: false },
              { key: "pattern_analysis", label: "Pattern Analysis",     done: !!inv.pattern_analysis, ai: false },
              { key: "red_flag_mapping", label: "Red Flag Mapping",     done: !!inv.red_flag_mapping, ai: false },
              { key: "narrative",        label: "Narrative Generation", done: !!inv.narrative,        ai: true  },
              { key: "qa_result",        label: "QA Validation",        done: !!inv.qa_result,        ai: false },
            ].map(({ key, label, done, ai }) => (
              <div key={key} className="flex items-center gap-2">
                {done ? (
                  <CheckCircle className="w-4 h-4 text-green-500 shrink-0" />
                ) : (
                  <div className="w-4 h-4 border-2 border-blue-400 border-t-transparent rounded-full animate-spin shrink-0" />
                )}
                <span className={done ? "text-green-700 font-medium" : "text-blue-700"}>{label}</span>
                {ai && <span className="text-xs bg-orange-100 text-orange-700 border border-orange-200 rounded-full px-1.5 py-0.5">real AI</span>}
              </div>
            ))}
          </div>
          <p className="text-xs text-blue-500 mt-3">
            Smart AI mode: only Narrative uses a real API call (1 credit). This page refreshes every 3 seconds.
          </p>
        </div>
      )}

      {inv.status === "failed" && (
        <div className="card p-4 border-red-200 bg-red-50 text-red-700 text-sm mb-6">
          <p className="font-semibold mb-1">Investigation failed</p>
          <p className="mt-1 font-mono text-xs bg-red-100 rounded p-2">{inv.error_message}</p>
          {inv.error_message?.includes("429") || inv.error_message?.includes("rate limit") ? (
            <div className="mt-3 pt-3 border-t border-red-200">
              <p className="font-semibold text-red-800 mb-2">Rate limit hit — what to do:</p>
              <ul className="space-y-1 text-red-700 text-xs list-disc ml-4">
                <li>Wait 60 seconds, then go back and <strong>retry with Claude</strong> instead of Gemini.</li>
                <li>Or set <code className="bg-red-100 px-1 rounded">MOCK_AI=true</code> in <code className="bg-red-100 px-1 rounded">.env</code> to bypass the API entirely.</li>
                <li>Gemini free tier: 15 req/min, 1M tokens/day. Each SAR narrative is ~1,000 tokens.</li>
              </ul>
              <Link href={`/alerts/${inv.alert_id}`}
                className="inline-flex items-center gap-2 mt-3 px-3 py-1.5 bg-red-700 text-white text-xs rounded-lg hover:bg-red-800">
                <ArrowLeft className="w-3 h-3" /> Go back &amp; retry with Claude
              </Link>
            </div>
          ) : null}
        </div>
      )}
      {inv.status === "closed" && (
        <div className="card p-4 border-slate-200 bg-slate-50 text-slate-600 text-sm mb-6">
          <p className="font-semibold">Investigation Closed / Monitor</p>
          <p className="mt-1">{inv.error_message}</p>
        </div>
      )}

      {/* Summary Stats */}
      {inv.pattern_analysis && (
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-6">
          {[
            { label: "Total Inbound",  value: formatCurrency(inv.evidence?.transaction_summary.total_inbound || 0), color: "text-emerald-600" },
            { label: "Total Outbound", value: formatCurrency(inv.evidence?.transaction_summary.total_outbound || 0), color: "text-rose-600" },
            { label: "Risk Level",     value: inv.pattern_analysis.overall_risk_level, color: "" },
            { label: "AI Confidence",  value: `${Math.round((inv.pattern_analysis.confidence_score || 0) * 100)}%`, color: "" },
          ].map((s) => (
            <div key={s.label} className="card p-4 text-center">
              <p className={`text-xl font-bold ${s.color}`}>{s.value}</p>
              <p className="text-xs text-slate-400 mt-0.5">{s.label}</p>
            </div>
          ))}
        </div>
      )}

      {/* Agent Pipeline Cards */}
      <h2 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-3">AI Agent Pipeline</h2>
      <div className="space-y-3">

        {/* Agent 1 – Evidence */}
        <AgentCard icon={<FileText className="w-4 h-4 text-blue-500" />}
          title="Evidence Collection Agent" status={inv.evidence ? "done" : inv.status === "failed" ? "error" : "pending"}>
          {inv.evidence && (
            <div className="grid grid-cols-2 gap-x-8 gap-y-2 text-sm">
              {[
                ["Customer",    inv.evidence.customer_profile?.customer_name],
                ["Business",    inv.evidence.customer_profile?.business_type],
                ["Risk Rating", inv.evidence.customer_profile?.risk_rating],
                ["Transactions",inv.evidence.transaction_summary?.transaction_count],
                ["PEP Status",  inv.evidence.kyc_summary?.pep ? "⚠️ PEP" : "Clear"],
                ["Beneficial Owner", inv.evidence.kyc_summary?.beneficial_owner_disclosed ? "✓ Disclosed" : "⚠️ Not Disclosed"],
                ["High-Risk Jurisdictions", inv.evidence.transaction_summary?.high_risk_jurisdictions?.join(", ") || "None"],
                ["Prior SARs",  inv.evidence.prior_sar_history?.length || 0],
              ].map(([k, v]) => (
                <div key={String(k)} className="flex justify-between border-b border-slate-100 pb-1">
                  <span className="text-slate-500">{k}</span>
                  <span className="font-medium">{String(v)}</span>
                </div>
              ))}
            </div>
          )}
        </AgentCard>

        {/* Agent 2 – Pattern */}
        <AgentCard icon={<BarChart2 className="w-4 h-4 text-purple-500" />}
          title="Pattern Analysis Agent" status={inv.pattern_analysis ? "done" : inv.status === "failed" ? "error" : "pending"}>
          {inv.pattern_analysis && (
            <div className="space-y-3">
              <div className="flex items-center gap-3 flex-wrap">
                <span className={`badge ${severityColor(inv.pattern_analysis.overall_risk_level)}`}>
                  {inv.pattern_analysis.overall_risk_level} Risk
                </span>
                <span className="text-sm text-slate-600">
                  Confidence: <strong>{Math.round((inv.pattern_analysis.confidence_score || 0) * 100)}%</strong>
                </span>
              </div>
              <div className="space-y-2">
                {inv.pattern_analysis.detected_patterns?.filter(p => p.triggered).map(p => (
                  <div key={p.rule} className="bg-amber-50 rounded-lg p-3 flex gap-3">
                    <span className="text-amber-500 shrink-0 mt-0.5">⚠</span>
                    <div>
                      <p className="font-semibold text-amber-900 text-sm">{p.rule}</p>
                      <p className="text-amber-700 text-xs mt-0.5">{p.evidence}</p>
                    </div>
                  </div>
                ))}
                {inv.pattern_analysis.detected_patterns?.filter(p => !p.triggered).map(p => (
                  <div key={p.rule} className="bg-slate-50 rounded-lg p-3 flex gap-3">
                    <span className="text-slate-400 shrink-0 mt-0.5">✓</span>
                    <p className="text-slate-500 text-sm">{p.rule} — not triggered</p>
                  </div>
                ))}
              </div>
              <p className="text-slate-500 text-sm italic mt-2">{inv.pattern_analysis.analyst_notes}</p>
            </div>
          )}
        </AgentCard>

        {/* Agent 3 – Red Flags */}
        <AgentCard icon={<Flag className="w-4 h-4 text-red-500" />}
          title="Red Flag Mapping Agent" status={inv.red_flag_mapping ? "done" : inv.status === "failed" ? "error" : "pending"}>
          {inv.red_flag_mapping && (
            <div className="space-y-3">
              <div className="flex gap-2 flex-wrap">
                <span className="badge bg-purple-100 text-purple-800 border-purple-200">
                  {inv.red_flag_mapping.money_laundering_stage} Stage
                </span>
                <span className={`badge ${inv.red_flag_mapping.recommended_action === "File SAR"
                  ? "bg-red-100 text-red-800 border-red-200"
                  : "bg-amber-100 text-amber-800 border-amber-200"}`}>
                  {inv.red_flag_mapping.recommended_action}
                </span>
              </div>
              <p className="text-sm text-slate-600">
                <span className="text-slate-400">Primary Typology:</span>{" "}
                <strong>{inv.red_flag_mapping.primary_typology}</strong>
              </p>
              <div className="space-y-2">
                {inv.red_flag_mapping.regulatory_red_flags?.map(f => (
                  <div key={f.flag_name} className="flex items-start gap-3 p-3 bg-red-50 rounded-lg">
                    <span className={`badge shrink-0 text-xs mt-0.5 ${f.regulatory_source === "FinCEN"
                      ? "bg-red-100 text-red-800 border-red-200"
                      : "bg-blue-100 text-blue-800 border-blue-200"}`}>
                      {f.regulatory_source}
                    </span>
                    <div>
                      <p className="font-semibold text-sm text-red-900">{f.flag_name}</p>
                      <p className="text-xs text-red-700 mt-0.5">{f.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </AgentCard>

        {/* Agent 4 – Narrative (preview only; full review on /narrative) */}
        <AgentCard icon={<BookOpen className="w-4 h-4 text-emerald-500" />}
          title="Narrative Generation Agent" status={inv.narrative ? "done" : inv.status === "failed" ? "error" : "pending"}>
          {inv.narrative && (
            <div className="space-y-3">
              <div className="flex gap-2 flex-wrap items-center">
                <span className={`badge ${inv.narrative.filing_recommendation === "File SAR"
                  ? "bg-red-100 text-red-800 border-red-200"
                  : "bg-green-100 text-green-800 border-green-200"}`}>
                  {inv.narrative.filing_recommendation}
                </span>
                {inv.narrative_approved && (
                  <span className="badge bg-green-100 text-green-800 border-green-200">
                    ✓ Narrative Approved by {inv.narrative_approved_by}
                  </span>
                )}
              </div>
              <div className="bg-slate-50 rounded-lg p-4">
                <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2">Activity Overview</p>
                <p className="text-sm text-slate-700 leading-relaxed">
                  {inv.narrative.narrative_sections?.activity_overview}
                </p>
              </div>
              <Link href={`/investigations/${inv.id}/narrative`}
                className="inline-flex items-center gap-2 text-sm text-blue-600 hover:text-blue-800 font-medium">
                Read full narrative & review <ArrowRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          )}
        </AgentCard>

        {/* Agent 5 – QA */}
        <AgentCard icon={<Shield className="w-4 h-4 text-teal-500" />}
          title="QA Validation Agent" status={inv.qa_result ? "done" : inv.status === "failed" ? "error" : "pending"}>
          {inv.qa_result && (
            <div className="space-y-3">
              <div className={`flex items-center gap-3 p-3 rounded-lg ${inv.qa_result.validation_passed ? "bg-green-50" : "bg-amber-50"}`}>
                <span className={`text-3xl font-bold ${inv.qa_result.validation_passed ? "text-green-600" : "text-amber-600"}`}>
                  {inv.qa_result.score}
                </span>
                <div>
                  <p className={`font-semibold text-sm ${inv.qa_result.validation_passed ? "text-green-800" : "text-amber-800"}`}>
                    {inv.qa_result.validation_passed ? "✓ Validation Passed" : "⚠ Review Recommended"} · Score /100
                  </p>
                  <p className="text-xs text-slate-500">{inv.qa_result.qa_summary}</p>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2">
                {inv.qa_result.checks?.map(c => (
                  <div key={c.check_name} className={`flex items-start gap-2 p-2 rounded text-xs ${c.passed ? "bg-green-50" : "bg-red-50"}`}>
                    <span className={c.passed ? "text-green-600" : "text-red-600"}>{c.passed ? "✓" : "✗"}</span>
                    <div>
                      <p className={`font-medium ${c.passed ? "text-green-800" : "text-red-800"}`}>{c.check_name}</p>
                      {c.note && <p className={`mt-0.5 ${c.passed ? "text-green-600" : "text-red-600"}`}>{c.note}</p>}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </AgentCard>
      </div>

      {/* Bottom CTA */}
      {inv.status === "narrative_ready" && (
        <div className="mt-6 card p-5 bg-blue-50 border-blue-200 flex items-center justify-between gap-4">
          <div>
            <p className="font-semibold text-blue-900">Narrative is ready for your review</p>
            <p className="text-sm text-blue-600 mt-0.5">Read the full AI-generated SAR narrative, then approve or regenerate it.</p>
          </div>
          <Link href={`/investigations/${inv.id}/narrative`} className="btn-primary shrink-0">
            Review Narrative <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      )}
      {inv.status === "sar_ready" && (
        <div className="mt-6 card p-5 bg-amber-50 border-amber-200 flex items-center justify-between gap-4">
          <div>
            <p className="font-semibold text-amber-900">SAR is ready for final approval</p>
            <p className="text-sm text-amber-600 mt-0.5">Review the structured SAR report, then approve or request revisions.</p>
          </div>
          <Link href={`/investigations/${inv.id}/sar`} className="btn-primary shrink-0 bg-amber-600 hover:bg-amber-700">
            Review SAR <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      )}
    </div>
  );
}
