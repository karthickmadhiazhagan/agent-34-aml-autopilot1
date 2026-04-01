"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { fetchInvestigation, approveSar, reviseSar, downloadSarPdf, formatCurrency } from "@/lib/api";
import type { Investigation } from "@/types";
import Link from "next/link";

export default function SarReviewPage() {
  const { id }  = useParams<{ id: string }>();
  const [inv, setInv]           = useState<Investigation | null>(null);
  const [loading, setLoading]   = useState(true);
  const [approving, setApproving] = useState(false);
  const [revising, setRevising] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    fetchInvestigation(Number(id)).then(setInv).finally(() => setLoading(false));
  }, [id]);

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(null), 4000);
  }

  async function handleApprove() {
    if (!inv) return;
    setApproving(true);
    try {
      const { investigation } = await approveSar(inv.id, "Lead Investigator");
      setInv(investigation);
      showToast("SAR approved! PDF is ready for download.");
    } catch (e: unknown) {
      showToast((e as Error).message);
    } finally {
      setApproving(false);
    }
  }

  async function handleRevise() {
    if (!inv) return;
    setRevising(true);
    try {
      const { investigation, message } = await reviseSar(inv.id);
      setInv(investigation);
      showToast(message);
    } catch (e: unknown) {
      showToast((e as Error).message);
    } finally {
      setRevising(false);
    }
  }

  async function handleDownloadPdf() {
    if (!inv) return;
    setDownloading(true);
    try {
      await downloadSarPdf(inv.id, inv.alert_id);
      showToast("PDF downloaded.");
    } catch (e: unknown) {
      showToast((e as Error).message);
    } finally {
      setDownloading(false);
    }
  }

  if (loading) return <p className="text-gray-500">Loading SAR…</p>;

  const sar      = inv?.sar_output;
  const canAct   = inv?.status === "sar_ready";
  const approved = inv?.sar_approved;

  return (
    <div>
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
          <h1 className="text-xl font-bold">SAR Report</h1>
          <p className="text-gray-500 text-sm">
            {inv?.alert_id} · {sar?.subject?.name}
            {approved && <span className="ml-2 text-green-700 font-semibold">✓ Approved by {inv?.sar_approved_by}</span>}
          </p>
        </div>

        <div className="flex gap-2 shrink-0">
          {canAct && (
            <>
              <button onClick={handleRevise} disabled={revising} className="btn-secondary">
                {revising ? "Revising…" : "Revise SAR"}
              </button>
              <button onClick={handleApprove} disabled={approving} className="btn-primary">
                {approving ? "Approving…" : "Approve SAR"}
              </button>
            </>
          )}
          {approved && (
            <button onClick={handleDownloadPdf} disabled={downloading} className="btn-primary">
              {downloading ? "Downloading…" : "Download PDF"}
            </button>
          )}
        </div>
      </div>

      {!sar ? (
        <p className="text-gray-500">SAR not yet generated.</p>
      ) : (
        <div>

          {/* Cover: Subject + Filing Decision */}
          <div className="border border-gray-300 p-4 bg-gray-50 mb-4">
            <p className="text-xs text-gray-500 uppercase mb-1">Suspicious Activity Report · FinCEN / BSA</p>
            <h2 className="text-lg font-bold">{sar.subject?.name}</h2>
            <p className="text-gray-600 text-sm">{sar.activity_type}</p>
            <p className="mt-2 font-bold">Filing Recommendation: {sar.filing_recommendation}</p>
            <table className="w-full text-sm border-collapse mt-3">
              <tbody>
                {[
                  ["Customer ID",    sar.subject?.customer_id],
                  ["Business Type",  sar.subject?.business_type],
                  ["Risk Rating",    sar.subject?.risk_rating],
                  ["Account Opened", sar.subject?.account_open_date],
                ].map(([label, value]) => (
                  <tr key={String(label)} className="border-b border-gray-200">
                    <td className="py-1 pr-4 text-gray-500">{label}</td>
                    <td className="py-1 font-medium">{String(value || "—")}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Transaction Summary */}
          <div className="border border-gray-300 p-4 mb-4">
            <h3 className="section-title">Transaction Summary</h3>
            <div className="text-sm flex gap-6 flex-wrap mb-3">
              <span>Inbound: <strong className="text-green-700">{formatCurrency(sar.transaction_summary?.total_inbound || 0)}</strong></span>
              <span>Outbound: <strong className="text-red-700">{formatCurrency(sar.transaction_summary?.total_outbound || 0)}</strong></span>
              <span>Transactions: <strong>{sar.transaction_summary?.transaction_count}</strong></span>
              <span>AI Confidence: <strong>{Math.round((sar.confidence_score || 0) * 100)}%</strong></span>
            </div>
            <table className="w-full text-sm border-collapse">
              <tbody>
                {[
                  ["Period",             `${sar.transaction_summary?.date_range?.from} – ${sar.transaction_summary?.date_range?.to}`],
                  ["ML Stage",           sar.money_laundering_stage],
                  ["Primary Typology",   sar.primary_typology],
                  ["High-Risk Jurisdictions", sar.transaction_summary?.high_risk_jurisdictions?.join(", ") || "None"],
                ].map(([label, value]) => (
                  <tr key={String(label)} className="border-b border-gray-100">
                    <td className="py-1 pr-4 text-gray-500 w-1/3">{label}</td>
                    <td className="py-1 font-medium">{String(value)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Red Flags */}
          {(sar.regulatory_red_flags?.length || 0) > 0 && (
            <div className="border border-red-300 p-4 mb-4">
              <h3 className="section-title">Regulatory Red Flags</h3>
              <table className="w-full border-collapse text-sm">
                <thead className="bg-gray-100">
                  <tr>
                    <th className="border border-gray-200 px-2 py-1 text-left">Flag</th>
                    <th className="border border-gray-200 px-2 py-1 text-left">Source</th>
                    <th className="border border-gray-200 px-2 py-1 text-left">Risk</th>
                    <th className="border border-gray-200 px-2 py-1 text-left">Description</th>
                  </tr>
                </thead>
                <tbody>
                  {sar.regulatory_red_flags?.map((f: { flag_name: string; regulatory_source: string; category: string; description: string; risk_weight: string }) => (
                    <tr key={f.flag_name} className="border-b border-gray-100">
                      <td className="border border-gray-200 px-2 py-1 font-medium">{f.flag_name}</td>
                      <td className="border border-gray-200 px-2 py-1 text-gray-500">{f.regulatory_source}</td>
                      <td className="border border-gray-200 px-2 py-1 text-gray-500">{f.risk_weight}</td>
                      <td className="border border-gray-200 px-2 py-1 text-gray-600">{f.description}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Narrative Sections */}
          <div className="border border-gray-300 p-4 mb-4">
            <h3 className="section-title">Investigation Narrative</h3>
            {Object.entries(sar.narrative_sections || {}).map(([key, text]) => {
              const labels: Record<string, string> = {
                customer_background:     "I. Customer Background",
                activity_overview:       "II. Activity Overview",
                suspicious_behavior:     "III. Suspicious Behavior",
                regulatory_indicators:   "IV. Regulatory Indicators",
                investigation_conclusion:"V. Investigation Conclusion",
              };
              return (
                <div key={key} className="mb-4">
                  <h4 className="font-bold text-gray-700 text-sm mb-1">{labels[key] || key}</h4>
                  <p className="text-sm text-gray-800 leading-relaxed bg-gray-50 border border-gray-200 p-3">{String(text)}</p>
                </div>
              );
            })}
          </div>

          {/* QA */}
          {inv?.qa_result && (
            <div className="border border-gray-200 p-4 mb-4 text-sm">
              <p className="font-bold mb-1">
                QA Score: {inv.qa_result.score}/100 — {inv.qa_result.validation_passed ? "✓ Passed" : "⚠ Review Recommended"}
              </p>
              <p className="text-gray-500">{inv.qa_result.qa_summary}</p>
            </div>
          )}

          {/* Approval Record */}
          {(inv?.narrative_approved || approved) && (
            <div className="border border-gray-300 p-4 mb-4">
              <h3 className="section-title">Approval Record</h3>
              <table className="w-full text-sm border-collapse">
                <tbody>
                  {[
                    ["Narrative Approved By", inv?.narrative_approved_by || "—"],
                    ["Narrative Approved At", inv?.narrative_approved_at ? new Date(inv.narrative_approved_at).toLocaleString() : "—"],
                    ["SAR Approved By",       inv?.sar_approved_by || "Pending"],
                    ["SAR Approved At",       inv?.sar_approved_at ? new Date(inv.sar_approved_at).toLocaleString() : "Pending"],
                  ].map(([label, value]) => (
                    <tr key={String(label)} className="border-b border-gray-100">
                      <td className="py-1 pr-4 text-gray-500 w-1/2">{label}</td>
                      <td className="py-1 font-medium">{String(value)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Bottom action bar */}
          {canAct && (
            <div className="border border-gray-300 p-4 flex items-center justify-between gap-4 bg-gray-50">
              <p className="text-sm">Ready to approve this SAR for filing?</p>
              <div className="flex gap-2">
                <button onClick={handleRevise} disabled={revising} className="btn-secondary">
                  {revising ? "Revising…" : "Revise SAR"}
                </button>
                <button onClick={handleApprove} disabled={approving} className="btn-primary">
                  {approving ? "Approving…" : "Approve SAR"}
                </button>
              </div>
            </div>
          )}

          {approved && (
            <div className="border border-green-400 bg-green-50 p-4 flex items-center justify-between gap-4">
              <p className="text-sm font-bold text-green-800">✓ SAR Approved — Ready for Filing</p>
              <button onClick={handleDownloadPdf} disabled={downloading} className="btn-primary">
                {downloading ? "Downloading…" : "Download SAR PDF"}
              </button>
            </div>
          )}

        </div>
      )}
    </div>
  );
}
