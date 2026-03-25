"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { fetchAlert, startInvestigation, formatCurrency, severityColor } from "@/lib/api";
import type { Alert } from "@/types";
import { ArrowLeft, Play, Clock, Shield, AlertTriangle, User, DollarSign } from "lucide-react";
import Link from "next/link";

export default function AlertDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [alert, setAlert] = useState<Alert | null>(null);
  const [investigations, setInvestigations] = useState<Array<{ id: number; status: string; created_at: string }>>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchAlert(id)
      .then(({ alert, investigations }) => {
        setAlert(alert);
        setInvestigations(investigations);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [id]);

  async function handleStartInvestigation() {
    setStarting(true);
    setError(null);
    try {
      const inv = await startInvestigation(id);
      router.push(`/investigations/${inv.id}`);
    } catch (e: unknown) {
      const err = e as Error;
      setError(err.message || "Failed to start investigation");
      setStarting(false);
    }
  }

  if (loading) {
    return (
      <div className="card p-12 text-center text-slate-400">
        <div className="inline-block w-8 h-8 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin mb-3" />
        <p>Loading alert details…</p>
      </div>
    );
  }

  if (error && !alert) {
    return (
      <div className="card p-6 border-red-200 bg-red-50 text-red-700">
        <p className="font-semibold">{error}</p>
      </div>
    );
  }

  if (!alert) return null;

  const passthroughRatio = alert.total_inbound > 0
    ? ((alert.total_outbound / alert.total_inbound) * 100).toFixed(1)
    : "0";

  return (
    <div>
      {/* Back */}
      <Link href="/" className="inline-flex items-center gap-2 text-sm text-slate-500 hover:text-slate-900 mb-6 transition-colors">
        <ArrowLeft className="w-4 h-4" /> Back to Alerts
      </Link>

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-8">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <span className={`badge ${severityColor(alert.severity)}`}>{alert.severity}</span>
            <span className="text-sm text-slate-400">{alert.alert_id}</span>
          </div>
          <h1 className="text-2xl font-bold text-slate-900">{alert.customer_profile.customer_name}</h1>
          <p className="text-slate-500 mt-1">{alert.alert_type} · Generated {alert.alert_generated_date}</p>
        </div>

        <button
          onClick={handleStartInvestigation}
          disabled={starting}
          className="btn-primary shrink-0"
        >
          {starting ? (
            <>
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
              Running AI Agents…
            </>
          ) : (
            <>
              <Play className="w-4 h-4" />
              Start Investigation
            </>
          )}
        </button>
      </div>

      {error && (
        <div className="card p-4 border-red-200 bg-red-50 text-red-700 text-sm mb-6">
          {error}
        </div>
      )}

      {starting && (
        <div className="card p-6 border-blue-200 bg-blue-50 mb-6">
          <p className="font-semibold text-blue-800">🤖 AI Agents are running…</p>
          <p className="text-sm text-blue-600 mt-1">
            The 5-agent pipeline is analyzing this alert. This typically takes 30–60 seconds.
            You'll be redirected to the investigation view automatically.
          </p>
          <div className="mt-4 space-y-2 text-sm text-blue-700">
            {["Evidence Collection", "Pattern Analysis", "Red Flag Mapping", "Narrative Generation", "QA Validation"].map((agent) => (
              <div key={agent} className="flex items-center gap-2">
                <div className="w-4 h-4 border-2 border-blue-400 border-t-transparent rounded-full animate-spin" />
                {agent} Agent
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column */}
        <div className="space-y-6">
          {/* Customer Profile */}
          <div className="card p-5">
            <p className="section-title flex items-center gap-2"><User className="w-3.5 h-3.5" />Customer Profile</p>
            <dl className="space-y-2 text-sm">
              {[
                ["Customer ID",   alert.customer_profile.customer_id],
                ["Business Type", alert.customer_profile.business_type],
                ["Account Opened", alert.customer_profile.account_open_date],
                ["Expected Turnover", formatCurrency(alert.customer_profile.expected_monthly_turnover) + "/mo"],
                ["Risk Rating",   alert.customer_profile.risk_rating],
              ].map(([label, value]) => (
                <div key={label} className="flex justify-between gap-2">
                  <dt className="text-slate-500">{label}</dt>
                  <dd className="font-medium text-right">{value}</dd>
                </div>
              ))}
            </dl>
          </div>

          {/* KYC */}
          <div className="card p-5">
            <p className="section-title flex items-center gap-2"><Shield className="w-3.5 h-3.5" />KYC Status</p>
            <dl className="space-y-2 text-sm">
              {[
                ["ID Verified",          alert.kyc.id_verified],
                ["Beneficial Owner",     alert.kyc.beneficial_owner_disclosed],
                ["PEP Status",           alert.kyc.pep_status ? "⚠️ PEP" : "Clear"],
                ["Sanctions Match",      alert.kyc.sanctions_match ? "🚨 Match" : "Clear"],
                ["Last KYC Review",      alert.kyc.last_kyc_review],
              ].map(([label, value]) => (
                <div key={String(label)} className="flex justify-between gap-2">
                  <dt className="text-slate-500">{label as string}</dt>
                  <dd className={`font-medium ${value === true ? "text-green-600" : value === false && label !== "PEP Status" && label !== "Sanctions Match" ? "text-red-600" : ""}`}>
                    {typeof value === "boolean" ? (value ? "✓ Yes" : "✗ No") : String(value)}
                  </dd>
                </div>
              ))}
            </dl>
          </div>

          {/* Prior SARs */}
          {alert.prior_sars.length > 0 && (
            <div className="card p-5 border-amber-200 bg-amber-50">
              <p className="section-title flex items-center gap-2 text-amber-600">
                <AlertTriangle className="w-3.5 h-3.5" />Prior SAR History
              </p>
              {alert.prior_sars.map((sar) => (
                <div key={sar.sar_id} className="text-sm">
                  <p className="font-medium text-amber-800">{sar.sar_id}</p>
                  <p className="text-amber-600">{sar.filed_date} · {sar.reason}</p>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Right Column – Transactions */}
        <div className="lg:col-span-2 space-y-6">
          {/* Transaction Summary */}
          <div className="grid grid-cols-3 gap-4">
            {[
              { label: "Total Inbound",  value: formatCurrency(alert.total_inbound),  color: "text-emerald-600" },
              { label: "Total Outbound", value: formatCurrency(alert.total_outbound), color: "text-rose-600" },
              { label: "Pass-Through %", value: `${passthroughRatio}%`,              color: Number(passthroughRatio) >= 90 ? "text-red-700 font-bold" : "text-slate-900" },
            ].map((stat) => (
              <div key={stat.label} className="card p-4 text-center">
                <p className={`text-xl font-bold ${stat.color}`}>{stat.value}</p>
                <p className="text-xs text-slate-400 mt-0.5">{stat.label}</p>
              </div>
            ))}
          </div>

          {/* Transaction Table */}
          <div className="card overflow-hidden">
            <div className="p-4 border-b border-slate-100">
              <p className="section-title flex items-center gap-2 mb-0"><DollarSign className="w-3.5 h-3.5" />Transaction History ({alert.transactions.length})</p>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-slate-50">
                  <tr>
                    {["Txn ID", "Date", "Type", "Amount", "Counterparty", "Country"].map((h) => (
                      <th key={h} className="px-4 py-2.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {alert.transactions.map((txn) => (
                    <tr key={txn.txn_id} className="hover:bg-slate-50">
                      <td className="px-4 py-2.5 font-mono text-xs text-slate-500">{txn.txn_id}</td>
                      <td className="px-4 py-2.5 text-slate-600">{txn.date}</td>
                      <td className="px-4 py-2.5">
                        <span className={`badge ${txn.type.includes("In") ? "bg-emerald-50 text-emerald-700 border-emerald-200" : "bg-rose-50 text-rose-700 border-rose-200"}`}>
                          {txn.type}
                        </span>
                      </td>
                      <td className={`px-4 py-2.5 font-semibold ${txn.type.includes("In") ? "text-emerald-700" : "text-rose-700"}`}>
                        {formatCurrency(txn.amount)}
                      </td>
                      <td className="px-4 py-2.5 text-slate-600 truncate max-w-xs">
                        {txn.originator || txn.beneficiary || txn.branch || "—"}
                      </td>
                      <td className="px-4 py-2.5 text-slate-400 font-mono text-xs">{txn.country || "US"}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Past Investigations */}
          {investigations.length > 0 && (
            <div className="card p-5">
              <p className="section-title flex items-center gap-2"><Clock className="w-3.5 h-3.5" />Previous Investigations</p>
              <div className="space-y-2">
                {investigations.map((inv) => (
                  <Link
                    key={inv.id}
                    href={`/investigations/${inv.id}`}
                    className="flex items-center justify-between p-3 rounded-lg bg-slate-50 hover:bg-slate-100 transition-colors text-sm"
                  >
                    <span className="text-slate-500">Investigation #{inv.id}</span>
                    <div className="flex items-center gap-3">
                      <span className={`badge ${inv.status === "completed" ? "bg-green-100 text-green-800 border-green-200" : "bg-gray-100 text-gray-600 border-gray-200"}`}>
                        {inv.status}
                      </span>
                      <span className="text-slate-400 text-xs">{new Date(inv.created_at).toLocaleDateString()}</span>
                    </div>
                  </Link>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
