"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { fetchInvestigation, exportSar, formatCurrency } from "@/lib/api";
import type { Investigation } from "@/types";
import { ArrowLeft, Download, CheckCircle } from "lucide-react";
import Link from "next/link";

export default function SarExportPage() {
  const { id } = useParams<{ id: string }>();
  const [inv, setInv] = useState<Investigation | null>(null);
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);
  const [exported, setExported] = useState(false);

  useEffect(() => {
    fetchInvestigation(Number(id))
      .then(setInv)
      .finally(() => setLoading(false));
  }, [id]);

  async function handleExport() {
    if (!inv) return;
    setExporting(true);
    try {
      const result = await exportSar(inv.id);
      // Download as JSON file
      const blob = new Blob([JSON.stringify(result, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `SAR_${inv.alert_id}_${new Date().toISOString().split("T")[0]}.json`;
      a.click();
      URL.revokeObjectURL(url);
      setExported(true);
    } finally {
      setExporting(false);
    }
  }

  if (loading) {
    return (
      <div className="card p-12 text-center text-slate-400">
        <div className="inline-block w-8 h-8 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin mb-3" />
        <p>Loading SAR output…</p>
      </div>
    );
  }

  const sar = inv?.sar_output;

  return (
    <div className="max-w-3xl">
      <Link href={`/investigations/${id}`} className="inline-flex items-center gap-2 text-sm text-slate-500 hover:text-slate-900 mb-6 transition-colors">
        <ArrowLeft className="w-4 h-4" /> Back to Investigation
      </Link>

      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">SAR Export</h1>
          <p className="text-slate-500">Structured output ready for regulatory filing</p>
        </div>
        {sar && (
          <button onClick={handleExport} disabled={exporting} className="btn-primary">
            {exporting ? (
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
            ) : exported ? (
              <CheckCircle className="w-4 h-4" />
            ) : (
              <Download className="w-4 h-4" />
            )}
            {exported ? "Downloaded" : "Download JSON"}
          </button>
        )}
      </div>

      {!sar ? (
        <div className="card p-6 text-slate-500">SAR output not available.</div>
      ) : (
        <div className="space-y-6">
          {/* Subject */}
          <div className="card p-6">
            <p className="section-title">Subject of Report</p>
            <dl className="grid grid-cols-2 gap-3 text-sm">
              {[
                ["Subject Name",  sar.subject.name],
                ["Customer ID",   sar.subject.customer_id],
                ["Business Type", sar.subject.business_type],
                ["Risk Rating",   sar.subject.risk_rating],
                ["Alert ID",      sar.alert_id],
                ["Activity Type", sar.activity_type],
              ].map(([label, value]) => (
                <div key={label}>
                  <dt className="text-slate-400 text-xs mb-0.5">{label}</dt>
                  <dd className="font-semibold">{value}</dd>
                </div>
              ))}
            </dl>
          </div>

          {/* Filing Status */}
          <div className={`card p-6 ${sar.filing_recommendation === "File SAR" ? "border-red-200 bg-red-50" : "border-green-200 bg-green-50"}`}>
            <p className="section-title">Filing Recommendation</p>
            <div className="flex items-center gap-4">
              <span className={`text-2xl font-bold ${sar.filing_recommendation === "File SAR" ? "text-red-700" : "text-green-700"}`}>
                {sar.filing_recommendation}
              </span>
              <div className="text-sm text-slate-600">
                <p>Money Laundering Stage: <strong>{sar.money_laundering_stage}</strong></p>
                <p>Primary Typology: <strong>{sar.primary_typology}</strong></p>
              </div>
            </div>
          </div>

          {/* Transaction Summary */}
          <div className="card p-6">
            <p className="section-title">Transaction Summary</p>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-center">
              <div>
                <p className="text-xl font-bold text-emerald-600">{formatCurrency(sar.transaction_summary.total_inbound)}</p>
                <p className="text-xs text-slate-400">Total Inbound</p>
              </div>
              <div>
                <p className="text-xl font-bold text-rose-600">{formatCurrency(sar.transaction_summary.total_outbound)}</p>
                <p className="text-xs text-slate-400">Total Outbound</p>
              </div>
              <div>
                <p className="text-xl font-bold">{sar.transaction_summary.transaction_count}</p>
                <p className="text-xs text-slate-400">Transactions</p>
              </div>
              <div>
                <p className="text-xl font-bold">{((sar.confidence_score || 0) * 100).toFixed(0)}%</p>
                <p className="text-xs text-slate-400">AI Confidence</p>
              </div>
            </div>
            <div className="mt-3 text-xs text-slate-400 text-center">
              Period: {sar.transaction_summary.date_range?.from} – {sar.transaction_summary.date_range?.to}
            </div>
          </div>

          {/* Red Flags */}
          <div className="card p-6">
            <p className="section-title">Red Flags Identified</p>
            <div className="flex flex-wrap gap-2">
              {(sar.red_flags || []).map((flag: string) => (
                <span key={flag} className="badge bg-red-50 text-red-700 border-red-200 text-xs">
                  {flag}
                </span>
              ))}
            </div>
          </div>

          {/* QA */}
          <div className="card p-6">
            <p className="section-title">Quality Assurance</p>
            <div className="flex items-center gap-4">
              <div className={`text-4xl font-bold ${(sar.qa_score || 0) >= 80 ? "text-green-600" : "text-amber-600"}`}>
                {sar.qa_score}
              </div>
              <div>
                <p className="font-semibold">{sar.qa_passed ? "✓ QA Passed" : "⚠ Review Required"}</p>
                <p className="text-xs text-slate-400">Automated validation score out of 100</p>
              </div>
            </div>
          </div>

          {/* Raw JSON Preview */}
          <div className="card overflow-hidden">
            <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between">
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">SAR JSON Output</p>
            </div>
            <pre className="p-4 text-xs text-slate-700 bg-slate-50 overflow-x-auto max-h-64 font-mono leading-relaxed">
              {JSON.stringify({
                subject: sar.subject,
                activity_type: sar.activity_type,
                filing_recommendation: sar.filing_recommendation,
                red_flags: sar.red_flags,
                money_laundering_stage: sar.money_laundering_stage,
                summary: sar.narrative_sections?.investigation_conclusion,
              }, null, 2)}
            </pre>
          </div>
        </div>
      )}
    </div>
  );
}
