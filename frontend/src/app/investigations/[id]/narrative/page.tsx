"use client";

import { useEffect, useState, useRef } from "react";
import { useParams, useRouter } from "next/navigation";
import { fetchInvestigation, approveNarrative, regenerateNarrative, closeInvestigation } from "@/lib/api";
import type { Investigation } from "@/types";
import { ArrowLeft, CheckCircle, RefreshCw, XCircle, BookOpen, Shield } from "lucide-react";
import Link from "next/link";

const SECTION_LABELS: Record<string, { label: string; color: string }> = {
  customer_background:     { label: "I. Customer Background",     color: "border-blue-400" },
  activity_overview:       { label: "II. Activity Overview",      color: "border-purple-400" },
  suspicious_behavior:     { label: "III. Suspicious Behavior",   color: "border-red-400" },
  regulatory_indicators:   { label: "IV. Regulatory Indicators",  color: "border-amber-400" },
  investigation_conclusion:{ label: "V. Investigation Conclusion", color: "border-green-400" },
};

export default function NarrativeReviewPage() {
  const { id } = useParams<{ id: string }>();
  const router  = useRouter();
  const [inv, setInv] = useState<Investigation | null>(null);
  const [loading, setLoading]       = useState(true);
  const [approving, setApproving]   = useState(false);
  const [regenerating, setRegenerating] = useState(false);
  const [closing, setClosing]       = useState(false);
  const [toast, setToast]           = useState<{ msg: string; type: "success"|"error"|"info" } | null>(null);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    fetchInvestigation(Number(id)).then(setInv).finally(() => setLoading(false));
  }, [id]);

  // Poll while regenerating — stop when narrative_ready or failed
  useEffect(() => {
    if (!regenerating) {
      if (pollRef.current) { clearInterval(pollRef.current); pollRef.current = null; }
      return;
    }
    pollRef.current = setInterval(async () => {
      try {
        const fresh = await fetchInvestigation(Number(id));
        if (fresh.status === "narrative_ready" || fresh.status === "failed") {
          setInv(fresh);
          setRegenerating(false);
          if (fresh.status === "narrative_ready") showToast("Narrative regenerated successfully!", "success");
          if (fresh.status === "failed") showToast(`Regeneration failed: ${fresh.error_message}`, "error");
        } else {
          setInv(fresh); // update progress
        }
      } catch { /* ignore transient errors */ }
    }, 3000);
    return () => { if (pollRef.current) clearInterval(pollRef.current); };
  }, [regenerating, id]);

  function showToast(msg: string, type: "success"|"error"|"info" = "info") {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 4000);
  }

  async function handleApprove() {
    if (!inv) return;
    setApproving(true);
    try {
      const { investigation } = await approveNarrative(inv.id, "Investigator");
      showToast("Narrative approved! SAR is being generated…", "success");
      setTimeout(() => router.push(`/investigations/${investigation.id}/sar`), 1200);
    } catch (e: unknown) {
      showToast((e as Error).message, "error");
      setApproving(false);
    }
  }

  async function handleRegenerate() {
    if (!inv) return;
    setRegenerating(true);
    try {
      const { message } = await regenerateNarrative(inv.id);
      showToast(message || "Regenerating narrative…", "info");
      // Don't setRegenerating(false) here — the poll useEffect watches for
      // narrative_ready / failed and stops polling + clears the flag.
    } catch (e: unknown) {
      showToast((e as Error).message, "error");
      setRegenerating(false);
    }
  }

  async function handleClose() {
    if (!inv) return;
    if (!confirm("Close this investigation as Close / Monitor? This cannot be undone.")) return;
    setClosing(true);
    try {
      await closeInvestigation(inv.id, "Narrative not approved by investigator");
      showToast("Investigation closed / monitor.", "info");
      setTimeout(() => router.push(`/investigations/${inv.id}`), 1200);
    } catch (e: unknown) {
      showToast((e as Error).message, "error");
      setClosing(false);
    }
  }

  if (loading) return (
    <div className="card p-12 text-center text-slate-400">
      <div className="inline-block w-8 h-8 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin mb-3" />
      <p>Loading narrative…</p>
    </div>
  );

  const narrative  = inv?.narrative;
  const isApproved = inv?.narrative_approved;
  // Allow actions when ready; keep buttons visible during regeneration so
  // user can approve immediately once the new narrative arrives.
  const canAct = inv?.status === "narrative_ready" || regenerating;

  return (
    <div className="max-w-4xl">
      {/* Toast */}
      {toast && (
        <div className={`fixed top-6 right-6 z-50 px-5 py-3 rounded-xl shadow-lg text-sm font-medium
          ${toast.type === "success" ? "bg-green-600 text-white" :
            toast.type === "error"   ? "bg-red-600 text-white" :
                                       "bg-blue-600 text-white"}`}>
          {toast.msg}
        </div>
      )}

      <Link href={`/investigations/${id}`}
        className="inline-flex items-center gap-2 text-sm text-slate-500 hover:text-slate-900 mb-6 transition-colors">
        <ArrowLeft className="w-4 h-4" /> Back to Investigation
      </Link>

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-8">
        <div className="flex items-start gap-3">
          <BookOpen className="w-6 h-6 text-emerald-600 mt-1 shrink-0" />
          <div>
            <h1 className="text-2xl font-bold text-slate-900">Narrative Review</h1>
            <p className="text-slate-500">
              {inv?.alert_id} · {inv?.alert_data?.customer_profile?.customer_name}
              {(inv?.regeneration_count || 0) > 0 && (
                <span className="ml-2 text-amber-600 text-xs font-semibold">
                  (Regenerated ×{inv?.regeneration_count})
                </span>
              )}
            </p>
          </div>
        </div>

        {/* Action buttons — only shown when narrative_ready */}
        {canAct && (
          <div className="flex gap-2 flex-wrap shrink-0">
            <button onClick={handleClose} disabled={closing}
              className="btn-secondary text-slate-500 border-slate-200">
              {closing
                ? <div className="w-4 h-4 border-2 border-slate-400 border-t-transparent rounded-full animate-spin" />
                : <XCircle className="w-4 h-4" />}
              Close / Monitor
            </button>
            <button onClick={handleRegenerate} disabled={regenerating}
              className="btn-secondary text-amber-700 border-amber-200 bg-amber-50 hover:bg-amber-100">
              {regenerating
                ? <div className="w-4 h-4 border-2 border-amber-400 border-t-transparent rounded-full animate-spin" />
                : <RefreshCw className="w-4 h-4" />}
              Regenerate
            </button>
            <button onClick={handleApprove} disabled={approving}
              className="btn-primary bg-green-600 hover:bg-green-700">
              {approving
                ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                : <CheckCircle className="w-4 h-4" />}
              Approve Narrative
            </button>
          </div>
        )}

        {isApproved && (
          <div className="flex items-center gap-2 text-sm text-green-700 font-semibold bg-green-50 border border-green-200 px-4 py-2 rounded-lg shrink-0">
            <CheckCircle className="w-4 h-4" />
            Approved by {inv?.narrative_approved_by}
          </div>
        )}
      </div>

      {regenerating && (
        <div className="card p-5 border-amber-200 bg-amber-50 mb-6">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-5 h-5 border-2 border-amber-500 border-t-transparent rounded-full animate-spin shrink-0" />
            <p className="font-semibold text-amber-900">Regenerating narrative — please wait…</p>
          </div>
          <div className="space-y-1.5 text-sm">
            {[
              { label: "Evidence Collection",  done: !!inv?.evidence },
              { label: "Pattern Analysis",     done: !!inv?.pattern_analysis },
              { label: "Red Flag Mapping",     done: !!inv?.red_flag_mapping },
              { label: "Narrative Generation", done: !!inv?.narrative && inv?.status === "narrative_ready", ai: true },
              { label: "QA Validation",        done: !!inv?.qa_result  && inv?.status === "narrative_ready" },
            ].map(({ label, done, ai }) => (
              <div key={label} className="flex items-center gap-2">
                {done
                  ? <CheckCircle className="w-4 h-4 text-green-500 shrink-0" />
                  : <div className="w-4 h-4 border-2 border-amber-400 border-t-transparent rounded-full animate-spin shrink-0" />}
                <span className={done ? "text-green-700 font-medium" : "text-amber-700"}>{label}</span>
                {ai && <span className="text-xs bg-orange-100 text-orange-700 border border-orange-200 rounded-full px-1.5 py-0.5">real AI</span>}
              </div>
            ))}
          </div>
          <p className="text-xs text-amber-500 mt-3">Page polls every 3 seconds automatically.</p>
        </div>
      )}

      {!narrative ? (
        <div className="card p-6 text-slate-500">Narrative not yet available.</div>
      ) : (
        <div className="space-y-5">

          {/* Filing header card */}
          <div className="card bg-slate-900 text-white p-6">
            <p className="text-xs text-slate-400 uppercase tracking-wider mb-2">Suspicious Activity Report</p>
            <h2 className="text-xl font-bold">{narrative.subject_name}</h2>
            <p className="text-slate-300 mt-1">{narrative.activity_type}</p>
            <div className="flex gap-3 mt-4 flex-wrap">
              <span className={`badge text-xs ${narrative.filing_recommendation === "File SAR"
                ? "bg-red-900 text-red-200 border-red-700"
                : "bg-green-900 text-green-200 border-green-700"}`}>
                ⚑ {narrative.filing_recommendation}
              </span>
              {inv?.red_flag_mapping && (
                <span className="badge bg-slate-700 text-slate-200 border-slate-600 text-xs">
                  {inv.red_flag_mapping.money_laundering_stage} Stage
                </span>
              )}
              {inv?.red_flag_mapping && (
                <span className="badge bg-slate-700 text-slate-200 border-slate-600 text-xs">
                  {inv.red_flag_mapping.primary_typology}
                </span>
              )}
            </div>
          </div>

          {/* Narrative Sections */}
          {Object.entries(narrative.narrative_sections || {}).map(([key, text]) => {
            const meta = SECTION_LABELS[key] || { label: key.replace(/_/g, " "), color: "border-slate-400" };
            return (
              <div key={key} className={`card p-6 border-l-4 ${meta.color}`}>
                <h3 className="font-bold text-slate-800 mb-3">{meta.label}</h3>
                <p className="text-slate-700 leading-relaxed text-sm">{text}</p>
              </div>
            );
          })}

          {/* Red flags */}
          {inv?.red_flag_mapping?.regulatory_red_flags && inv.red_flag_mapping.regulatory_red_flags.length > 0 && (
            <div className="card p-6 bg-red-50 border-red-200">
              <h3 className="font-bold text-red-900 mb-3 flex items-center gap-2">
                <span>⚑</span> Regulatory Red Flags
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                {inv.red_flag_mapping.regulatory_red_flags.map(f => (
                  <div key={f.flag_name} className="flex items-center gap-2 text-sm">
                    <span className={`badge text-xs shrink-0 ${f.regulatory_source === "FinCEN"
                      ? "bg-red-100 text-red-800 border-red-200"
                      : "bg-blue-100 text-blue-800 border-blue-200"}`}>
                      {f.regulatory_source}
                    </span>
                    <span className="text-red-800 font-medium">{f.flag_name}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* QA Score */}
          {inv?.qa_result && (
            <div className={`card p-5 flex items-center gap-5 ${inv.qa_result.validation_passed
              ? "border-green-200 bg-green-50" : "border-amber-200 bg-amber-50"}`}>
              <div className={`text-4xl font-bold shrink-0 ${inv.qa_result.validation_passed ? "text-green-600" : "text-amber-600"}`}>
                {inv.qa_result.score}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <Shield className="w-4 h-4" />
                  <p className={`font-semibold ${inv.qa_result.validation_passed ? "text-green-800" : "text-amber-800"}`}>
                    QA Score /100 — {inv.qa_result.validation_passed ? "Validation Passed" : "Review Recommended"}
                  </p>
                </div>
                <p className="text-sm text-slate-600 mt-1">{inv.qa_result.qa_summary}</p>
              </div>
            </div>
          )}

          {/* Bottom action bar */}
          {canAct && (
            <div className="card p-5 flex flex-col sm:flex-row items-center justify-between gap-4 bg-slate-50">
              <div>
                <p className="font-semibold text-slate-800">Is this narrative ready to file?</p>
                <p className="text-sm text-slate-500">Approve to proceed to SAR, or regenerate if the narrative needs improvement.</p>
              </div>
              <div className="flex gap-3 shrink-0">
                <button onClick={handleClose} disabled={closing} className="btn-secondary">
                  <XCircle className="w-4 h-4" /> Close / Monitor
                </button>
                <button onClick={handleRegenerate} disabled={regenerating}
                  className="btn-secondary text-amber-700 border-amber-200 bg-amber-50 hover:bg-amber-100">
                  <RefreshCw className="w-4 h-4" />
                  {regenerating ? "Regenerating…" : "Regenerate"}
                </button>
                <button onClick={handleApprove} disabled={approving} className="btn-primary bg-green-600 hover:bg-green-700">
                  <CheckCircle className="w-4 h-4" />
                  {approving ? "Approving…" : "Approve Narrative"}
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
