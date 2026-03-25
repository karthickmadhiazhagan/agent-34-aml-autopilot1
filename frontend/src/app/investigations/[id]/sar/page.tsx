"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { fetchInvestigation, approveSar, reviseSar, downloadSarPdf, formatCurrency, severityColor } from "@/lib/api";
import type { Investigation } from "@/types";
import {
  ArrowLeft, CheckCircle, RefreshCw, Download, FileText,
  TrendingUp, TrendingDown, Flag, Shield
} from "lucide-react";
import Link from "next/link";

export default function SarReviewPage() {
  const { id }  = useParams<{ id: string }>();
  const router  = useRouter();
  const [inv, setInv]           = useState<Investigation | null>(null);
  const [loading, setLoading]   = useState(true);
  const [approving, setApproving] = useState(false);
  const [revising, setRevising] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [toast, setToast] = useState<{ msg: string; type: "success"|"error"|"info" } | null>(null);

  useEffect(() => {
    fetchInvestigation(Number(id)).then(setInv).finally(() => setLoading(false));
  }, [id]);

  function showToast(msg: string, type: "success"|"error"|"info" = "info") {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 4000);
  }

  async function handleApprove() {
    if (!inv) return;
    setApproving(true);
    try {
      const { investigation } = await approveSar(inv.id, "Lead Investigator");
      setInv(investigation);
      showToast("SAR approved! PDF is ready for download.", "success");
    } catch (e: unknown) {
      showToast((e as Error).message, "error");
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
      showToast(message, "info");
    } catch (e: unknown) {
      showToast((e as Error).message, "error");
    } finally {
      setRevising(false);
    }
  }

  async function handleDownloadPdf() {
    if (!inv) return;
    setDownloading(true);
    try {
      await downloadSarPdf(inv.id, inv.alert_id);
      showToast("PDF downloaded successfully.", "success");
    } catch (e: unknown) {
      showToast((e as Error).message, "error");
    } finally {
      setDownloading(false);
    }
  }

  if (loading) return (
    <div className="card p-12 text-center text-slate-400">
      <div className="inline-block w-8 h-8 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin mb-3" />
      <p>Loading SAR…</p>
    </div>
  );

  const sar      = inv?.sar_output;
  const canAct   = inv?.status === "sar_ready";
  const approved = inv?.sar_approved;

  return (
    <div className="max-w-5xl">
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
          <FileText className="w-6 h-6 text-blue-600 mt-1 shrink-0" />
          <div>
            <h1 className="text-2xl font-bold text-slate-900">SAR Report</h1>
            <p className="text-slate-500">
              {inv?.alert_id} · {sar?.subject?.name}
              {approved && <span className="ml-2 text-green-600 font-semibold text-xs">✓ Approved by {inv?.sar_approved_by}</span>}
            </p>
          </div>
        </div>

        <div className="flex gap-2 flex-wrap shrink-0">
          {canAct && (
            <>
              <button onClick={handleRevise} disabled={revising}
                className="btn-secondary text-amber-700 border-amber-200 bg-amber-50 hover:bg-amber-100">
                {revising
                  ? <div className="w-4 h-4 border-2 border-amber-400 border-t-transparent rounded-full animate-spin" />
                  : <RefreshCw className="w-4 h-4" />}
                Revise SAR
              </button>
              <button onClick={handleApprove} disabled={approving} className="btn-primary bg-green-600 hover:bg-green-700">
                {approving
                  ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  : <CheckCircle className="w-4 h-4" />}
                Approve SAR
              </button>
            </>
          )}
          {approved && (
            <button onClick={handleDownloadPdf} disabled={downloading} className="btn-primary">
              {downloading
                ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                : <Download className="w-4 h-4" />}
              Download PDF
            </button>
          )}
          {!canAct && !approved && sar && (
            <span className="badge bg-slate-100 text-slate-500 border-slate-200 text-xs px-3 py-1.5">
              {inv?.status}
            </span>
          )}
        </div>
      </div>

      {!sar ? (
        <div className="card p-6 text-slate-500">SAR not yet generated.</div>
      ) : (
        <div className="space-y-6">

          {/* ── Cover Sheet ── */}
          <div className="card overflow-hidden">
            <div className="bg-slate-900 text-white p-6">
              <div className="flex items-start justify-between gap-4 flex-wrap">
                <div>
                  <p className="text-xs text-slate-400 uppercase tracking-widest mb-2">
                    Suspicious Activity Report · FinCEN / BSA
                  </p>
                  <h2 className="text-2xl font-bold">{sar.subject?.name}</h2>
                  <p className="text-slate-300 mt-1">{sar.activity_type}</p>
                </div>
                <div className="text-right">
                  <span className={`badge text-sm px-4 py-1.5 ${sar.filing_recommendation === "File SAR"
                    ? "bg-red-700 text-white border-red-600"
                    : "bg-green-700 text-white border-green-600"}`}>
                    {sar.filing_recommendation}
                  </span>
                  <p className="text-xs text-slate-400 mt-2">Alert {sar.alert_id}</p>
                </div>
              </div>
            </div>

            {/* Subject details */}
            <div className="p-6 grid grid-cols-2 sm:grid-cols-4 gap-4">
              {[
                ["Customer ID",    sar.subject?.customer_id],
                ["Business Type",  sar.subject?.business_type],
                ["Risk Rating",    sar.subject?.risk_rating],
                ["Account Opened", sar.subject?.account_open_date],
              ].map(([label, value]) => (
                <div key={label}>
                  <p className="text-xs text-slate-400 uppercase tracking-wide mb-1">{label}</p>
                  <p className="font-semibold text-slate-800">{value || "—"}</p>
                </div>
              ))}
            </div>
          </div>

          {/* ── Transaction Summary ── */}
          <div className="card p-6">
            <h3 className="font-bold text-slate-800 mb-4 flex items-center gap-2">
              <TrendingUp className="w-4 h-4 text-blue-600" /> Transaction Summary
            </h3>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-4">
              {[
                { label: "Total Inbound",  value: formatCurrency(sar.transaction_summary?.total_inbound || 0), icon: <TrendingUp className="w-4 h-4" />, color: "text-emerald-600 bg-emerald-50" },
                { label: "Total Outbound", value: formatCurrency(sar.transaction_summary?.total_outbound || 0), icon: <TrendingDown className="w-4 h-4" />, color: "text-rose-600 bg-rose-50" },
                { label: "Transactions",   value: String(sar.transaction_summary?.transaction_count || 0), icon: <FileText className="w-4 h-4" />, color: "text-blue-600 bg-blue-50" },
                { label: "AI Confidence",  value: `${Math.round((sar.confidence_score || 0) * 100)}%`, icon: <Shield className="w-4 h-4" />, color: "text-purple-600 bg-purple-50" },
              ].map(s => (
                <div key={s.label} className={`rounded-xl p-4 ${s.color.split(" ")[1]}`}>
                  <div className={`flex items-center gap-2 ${s.color.split(" ")[0]} mb-1`}>
                    {s.icon}<span className="text-xl font-bold">{s.value}</span>
                  </div>
                  <p className="text-xs text-slate-500">{s.label}</p>
                </div>
              ))}
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm">
              <div><p className="text-slate-400 text-xs mb-0.5">Period</p>
                <p className="font-medium">{sar.transaction_summary?.date_range?.from} – {sar.transaction_summary?.date_range?.to}</p></div>
              <div><p className="text-slate-400 text-xs mb-0.5">ML Stage</p>
                <p className="font-medium">{sar.money_laundering_stage}</p></div>
              <div><p className="text-slate-400 text-xs mb-0.5">Primary Typology</p>
                <p className="font-medium">{sar.primary_typology}</p></div>
              {(sar.transaction_summary?.high_risk_jurisdictions?.length || 0) > 0 && (
                <div className="col-span-full">
                  <p className="text-slate-400 text-xs mb-1">High-Risk Jurisdictions</p>
                  <div className="flex gap-1.5 flex-wrap">
                    {sar.transaction_summary?.high_risk_jurisdictions?.map((j: string) => (
                      <span key={j} className="badge bg-red-50 text-red-700 border-red-200 text-xs">{j}</span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* ── Red Flags ── */}
          {(sar.regulatory_red_flags?.length || 0) > 0 && (
            <div className="card p-6">
              <h3 className="font-bold text-slate-800 mb-4 flex items-center gap-2">
                <Flag className="w-4 h-4 text-red-600" /> Regulatory Red Flags
              </h3>
              <div className="space-y-3">
                {sar.regulatory_red_flags?.map((f: { flag_name: string; regulatory_source: string; category: string; description: string; risk_weight: string }) => (
                  <div key={f.flag_name} className="flex items-start gap-4 p-4 bg-red-50 rounded-xl border border-red-100">
                    <div className="flex flex-col items-center gap-1.5 shrink-0">
                      <span className={`badge text-xs ${f.regulatory_source === "FinCEN"
                        ? "bg-red-100 text-red-800 border-red-200"
                        : "bg-blue-100 text-blue-800 border-blue-200"}`}>
                        {f.regulatory_source}
                      </span>
                      <span className={`badge text-xs ${f.risk_weight === "High" || f.risk_weight === "Critical"
                        ? "bg-orange-100 text-orange-800 border-orange-200"
                        : "bg-slate-100 text-slate-600 border-slate-200"}`}>
                        {f.risk_weight}
                      </span>
                    </div>
                    <div>
                      <p className="font-semibold text-red-900">{f.flag_name}</p>
                      <p className="text-xs text-red-600 mt-0.5">{f.category}</p>
                      <p className="text-sm text-slate-600 mt-1.5">{f.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* ── Narrative Sections ── */}
          <div className="card p-6">
            <h3 className="font-bold text-slate-800 mb-5 flex items-center gap-2">
              <FileText className="w-4 h-4 text-emerald-600" /> Investigation Narrative
            </h3>
            <div className="space-y-5">
              {Object.entries(sar.narrative_sections || {}).map(([key, text]) => {
                const labels: Record<string, string> = {
                  customer_background:     "I. Customer Background",
                  activity_overview:       "II. Activity Overview",
                  suspicious_behavior:     "III. Suspicious Behavior",
                  regulatory_indicators:   "IV. Regulatory Indicators",
                  investigation_conclusion:"V. Investigation Conclusion",
                };
                return (
                  <div key={key}>
                    <h4 className="font-semibold text-blue-700 mb-2 text-sm">{labels[key] || key}</h4>
                    <p className="text-sm text-slate-700 leading-relaxed bg-slate-50 rounded-lg p-4">{String(text)}</p>
                  </div>
                );
              })}
            </div>
          </div>

          {/* ── QA ── */}
          {inv?.qa_result && (
            <div className={`card p-5 flex items-start gap-5 ${inv.qa_result.validation_passed
              ? "border-green-200 bg-green-50" : "border-amber-200 bg-amber-50"}`}>
              <div className={`text-4xl font-bold shrink-0 ${inv.qa_result.validation_passed ? "text-green-600" : "text-amber-600"}`}>
                {inv.qa_result.score}
              </div>
              <div>
                <p className={`font-bold ${inv.qa_result.validation_passed ? "text-green-800" : "text-amber-800"}`}>
                  <Shield className="w-4 h-4 inline mr-1.5" />
                  QA Score /100 — {inv.qa_result.validation_passed ? "Validation Passed" : "Review Recommended"}
                </p>
                <p className="text-sm text-slate-600 mt-1">{inv.qa_result.qa_summary}</p>
              </div>
            </div>
          )}

          {/* ── Approval record ── */}
          {(inv?.narrative_approved || approved) && (
            <div className="card p-5 bg-slate-50">
              <h3 className="font-bold text-slate-700 text-sm mb-3 uppercase tracking-wider">Approval Record</h3>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <p className="text-slate-400 text-xs">Narrative Approved By</p>
                  <p className="font-medium">{inv?.narrative_approved_by || "—"}</p>
                </div>
                <div>
                  <p className="text-slate-400 text-xs">Narrative Approved At</p>
                  <p className="font-medium">{inv?.narrative_approved_at ? new Date(inv.narrative_approved_at).toLocaleString() : "—"}</p>
                </div>
                <div>
                  <p className="text-slate-400 text-xs">SAR Approved By</p>
                  <p className="font-medium">{inv?.sar_approved_by || "Pending"}</p>
                </div>
                <div>
                  <p className="text-slate-400 text-xs">SAR Approved At</p>
                  <p className="font-medium">{inv?.sar_approved_at ? new Date(inv.sar_approved_at).toLocaleString() : "Pending"}</p>
                </div>
              </div>
            </div>
          )}

          {/* ── Bottom action bar ── */}
          {canAct && (
            <div className="card p-5 flex flex-col sm:flex-row items-center justify-between gap-4 bg-amber-50 border-amber-200">
              <div>
                <p className="font-semibold text-amber-900">Ready to approve this SAR for filing?</p>
                <p className="text-sm text-amber-700">Approve to generate the final PDF, or revise to re-compose the SAR output.</p>
              </div>
              <div className="flex gap-3 shrink-0">
                <button onClick={handleRevise} disabled={revising}
                  className="btn-secondary text-amber-700 border-amber-200 bg-white hover:bg-amber-50">
                  <RefreshCw className="w-4 h-4" />
                  {revising ? "Revising…" : "Revise SAR"}
                </button>
                <button onClick={handleApprove} disabled={approving} className="btn-primary bg-green-600 hover:bg-green-700">
                  <CheckCircle className="w-4 h-4" />
                  {approving ? "Approving…" : "Approve SAR"}
                </button>
              </div>
            </div>
          )}

          {approved && (
            <div className="card p-5 flex items-center justify-between gap-4 bg-green-50 border-green-200">
              <div>
                <p className="font-bold text-green-900">✓ SAR Approved — Ready for Filing</p>
                <p className="text-sm text-green-700">Download the official SAR PDF for FinCEN submission.</p>
              </div>
              <button onClick={handleDownloadPdf} disabled={downloading} className="btn-primary">
                {downloading
                  ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  : <Download className="w-4 h-4" />}
                Download SAR PDF
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
