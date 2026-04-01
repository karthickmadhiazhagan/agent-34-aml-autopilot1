"use client";

import { useEffect, useState, useRef } from "react";
import { useParams, useRouter } from "next/navigation";
import { fetchInvestigation, approveNarrative, regenerateNarrative, closeInvestigation } from "@/lib/api";
import type { Investigation } from "@/types";
import Link from "next/link";

const SECTION_LABELS: Record<string, string> = {
  customer_background:     "I. Customer Background",
  activity_overview:       "II. Activity Overview",
  suspicious_behavior:     "III. Suspicious Behavior",
  regulatory_indicators:   "IV. Regulatory Indicators",
  investigation_conclusion:"V. Investigation Conclusion",
};

export default function NarrativeReviewPage() {
  const { id } = useParams<{ id: string }>();
  const router  = useRouter();
  const [inv, setInv] = useState<Investigation | null>(null);
  const [loading, setLoading]       = useState(true);
  const [approving, setApproving]   = useState(false);
  const [regenerating, setRegenerating] = useState(false);
  const [closing, setClosing]       = useState(false);
  const [toast, setToast]           = useState<string | null>(null);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    fetchInvestigation(Number(id)).then(setInv).finally(() => setLoading(false));
  }, [id]);

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
          showToast(fresh.status === "narrative_ready" ? "Narrative regenerated!" : `Failed: ${fresh.error_message}`);
        } else {
          setInv(fresh);
        }
      } catch { /* ignore */ }
    }, 3000);
    return () => { if (pollRef.current) clearInterval(pollRef.current); };
  }, [regenerating, id]);

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 4000);
  }

  async function handleApprove() {
    if (!inv) return;
    setApproving(true);
    try {
      const { investigation } = await approveNarrative(inv.id, "Investigator");
      showToast("Narrative approved! Redirecting to SAR…");
      setTimeout(() => router.push(`/investigations/${investigation.id}/sar`), 1200);
    } catch (e: unknown) {
      showToast((e as Error).message);
      setApproving(false);
    }
  }

  async function handleRegenerate() {
    if (!inv) return;
    setRegenerating(true);
    try {
      const { message } = await regenerateNarrative(inv.id);
      showToast(message || "Regenerating narrative…");
    } catch (e: unknown) {
      showToast((e as Error).message);
      setRegenerating(false);
    }
  }

  async function handleClose() {
    if (!inv) return;
    if (!confirm("Close this investigation as Close / Monitor?")) return;
    setClosing(true);
    try {
      await closeInvestigation(inv.id, "Narrative not approved by investigator");
      showToast("Investigation closed.");
      setTimeout(() => router.push(`/investigations/${inv.id}`), 1200);
    } catch (e: unknown) {
      showToast((e as Error).message);
      setClosing(false);
    }
  }

  if (loading) return <p className="text-gray-500">Loading narrative…</p>;

  const narrative  = inv?.narrative;
  const isApproved = inv?.narrative_approved;
  const canAct     = inv?.status === "narrative_ready" || regenerating;

  return (
    <div>
      {/* Toast */}
      {toast && (
        <div className="fixed top-4 right-4 z-50 border border-gray-400 bg-white px-4 py-2 text-sm shadow">
          {toast}
        </div>
      )}

      <Link href={`/investigations/${id}`} className="text-blue-600 hover:underline text-sm">
        &larr; Back to Investigation
      </Link>

      {/* Header */}
      <div className="mt-4 mb-4 flex items-start justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold">Narrative Review</h1>
          <p className="text-gray-500 text-sm">
            {inv?.alert_id} · {inv?.alert_data?.customer?.name}
            {(inv?.regeneration_count || 0) > 0 && (
              <span className="ml-2 text-gray-400">(Regenerated ×{inv?.regeneration_count})</span>
            )}
          </p>
        </div>

        <div className="flex gap-2 shrink-0">
          {canAct && (
            <>
              <button onClick={handleClose} disabled={closing} className="btn-secondary">
                {closing ? "Closing…" : "Close / Monitor"}
              </button>
              <button onClick={handleRegenerate} disabled={regenerating} className="btn-secondary">
                {regenerating ? "Regenerating…" : "Regenerate"}
              </button>
              <button onClick={handleApprove} disabled={approving} className="btn-primary">
                {approving ? "Approving…" : "Approve Narrative"}
              </button>
            </>
          )}
          {isApproved && (
            <span className="text-green-700 text-sm font-semibold border border-green-400 px-3 py-1">
              ✓ Approved by {inv?.narrative_approved_by}
            </span>
          )}
        </div>
      </div>

      {regenerating && (
        <div className="border border-yellow-400 bg-yellow-50 p-3 text-sm mb-4">
          <p className="font-semibold mb-2">Regenerating narrative — please wait… (auto-refreshes every 3s)</p>
          <ul className="space-y-0.5">
            {[
              { label: "Evidence Collection",  done: !!inv?.evidence },
              { label: "Pattern Analysis",     done: !!inv?.pattern_analysis },
              { label: "Red Flag Mapping",     done: !!inv?.red_flag_mapping },
              { label: "Narrative Generation", done: !!inv?.narrative && inv?.status === "narrative_ready" },
              { label: "QA Validation",        done: !!inv?.qa_result && inv?.status === "narrative_ready" },
            ].map(({ label, done }) => (
              <li key={label} className={done ? "text-green-700" : "text-yellow-800"}>
                {done ? "✓" : "○"} {label}
              </li>
            ))}
          </ul>
        </div>
      )}

      {!narrative ? (
        <p className="text-gray-500">Narrative not yet available.</p>
      ) : (
        <div>
          {/* Filing header */}
          <div className="border border-gray-300 p-4 bg-gray-50 mb-4">
            <p className="text-xs text-gray-500 uppercase mb-1">Suspicious Activity Report</p>
            <h2 className="text-lg font-bold">{narrative.subject_name}</h2>
            <p className="text-gray-600 text-sm">{narrative.activity_type}</p>
            <div className="flex gap-3 mt-2 flex-wrap text-sm">
              <span className="font-bold">Recommendation: {narrative.filing_recommendation}</span>
              {inv?.red_flag_mapping && (
                <span className="text-gray-500">Stage: {inv.red_flag_mapping.money_laundering_stage} · {inv.red_flag_mapping.primary_typology}</span>
              )}
            </div>
          </div>

          {/* Narrative Sections */}
          {Object.entries(narrative.narrative_sections || {}).map(([key, text]) => (
            <div key={key} className="border border-gray-200 p-4 mb-3">
              <h3 className="font-bold text-gray-700 mb-2 text-sm">
                {SECTION_LABELS[key] || key.replace(/_/g, " ")}
              </h3>
              <p className="text-sm text-gray-800 leading-relaxed">{text}</p>
            </div>
          ))}

          {/* Red Flags */}
          {inv?.red_flag_mapping?.regulatory_red_flags && inv.red_flag_mapping.regulatory_red_flags.length > 0 && (
            <div className="border border-red-300 p-4 mb-3">
              <h3 className="font-bold text-red-800 mb-2 text-sm">Regulatory Red Flags</h3>
              <ul className="text-sm space-y-1">
                {inv.red_flag_mapping.regulatory_red_flags.map(f => (
                  <li key={f.flag_name} className="text-red-700">
                    [{f.regulatory_source}] {f.flag_name}
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* QA Score */}
          {inv?.qa_result && (
            <div className="border border-gray-200 p-4 mb-3 text-sm">
              <p className="font-bold mb-1">
                QA Score: {inv.qa_result.score}/100 — {inv.qa_result.validation_passed ? "✓ Passed" : "⚠ Review Recommended"}
              </p>
              <p className="text-gray-500">{inv.qa_result.qa_summary}</p>
            </div>
          )}

          {/* Bottom action bar */}
          {canAct && (
            <div className="border border-gray-300 p-4 flex items-center justify-between gap-4 bg-gray-50 mt-4">
              <p className="text-sm">Is this narrative ready to file?</p>
              <div className="flex gap-2">
                <button onClick={handleClose} disabled={closing} className="btn-secondary">
                  {closing ? "Closing…" : "Close / Monitor"}
                </button>
                <button onClick={handleRegenerate} disabled={regenerating} className="btn-secondary">
                  {regenerating ? "Regenerating…" : "Regenerate"}
                </button>
                <button onClick={handleApprove} disabled={approving} className="btn-primary">
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
