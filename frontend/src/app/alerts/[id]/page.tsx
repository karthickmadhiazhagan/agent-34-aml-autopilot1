"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { fetchAlert, startInvestigation, formatCurrency, severityColor } from "@/lib/api";
import type { Alert, Transaction } from "@/types";
import { ArrowLeft, Play, Clock, Shield, AlertTriangle, User, DollarSign, MapPin } from "lucide-react";
import Link from "next/link";

// Determine if a transaction is inbound to the subject account
function isInbound(txn: Transaction): boolean {
  if (txn.type === "cash_deposit" || txn.type === "crypto_conversion") return true;
  if (txn.type === "cash_withdrawal") return false;
  return txn.from_account === null; // external source → inbound
}

function txnDirection(txn: Transaction) {
  return isInbound(txn) ? "Inbound" : "Outbound";
}

function kycLabel(status: string) {
  const map: Record<string, string> = {
    verified: "✓ Verified",
    pending: "⏳ Pending",
    failed: "✗ Failed",
    enhanced_due_diligence: "⚠ EDD Required",
  };
  return map[status] || status;
}

function kycColor(status: string) {
  if (status === "verified") return "text-green-600";
  if (status === "failed") return "text-red-600";
  return "text-amber-600";
}

export default function AlertDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [alert, setAlert] = useState<Alert | null>(null);
  const [investigations, setInvestigations] = useState<Array<{ id: number; status: string; created_at: string }>>([]);
  const [loading, setLoading] = useState(true);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [aiProvider, setAiProvider] = useState<"claude" | "gemini">("gemini");

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
      const inv = await startInvestigation(alert!.alert_id, aiProvider);
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

  const txns = alert.transactions || [];
  const inboundTotal  = txns.filter(isInbound).reduce((s, t) => s + t.amount, 0);
  const outboundTotal = txns.filter(t => !isInbound(t)).reduce((s, t) => s + t.amount, 0);
  const passthroughRatio = inboundTotal > 0 ? ((outboundTotal / inboundTotal) * 100).toFixed(1) : "0";
  const severityLabel = alert.severity.charAt(0) + alert.severity.slice(1).toLowerCase();

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
            <span className={`badge ${severityColor(severityLabel)}`}>{severityLabel}</span>
            <span className="text-sm text-slate-400 font-mono">{alert.alert_id}</span>
          </div>
          <h1 className="text-2xl font-bold text-slate-900">{alert.customer.name}</h1>
          <p className="text-slate-500 mt-1">{alert.alert_type}</p>
        </div>

        <div className="flex items-center gap-2 shrink-0">
          {/* AI Provider Dropdown */}
          <select
            value={aiProvider}
            onChange={(e) => setAiProvider(e.target.value as "claude" | "gemini")}
            disabled={starting}
            className="text-sm border border-slate-200 rounded-lg px-3 py-2 bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-blue-500 cursor-pointer"
          >
            <option value="gemini">✨ Gemini Flash (Google)</option>
            <option value="claude">🤖 Claude (Anthropic)</option>
          </select>

          <button
            onClick={handleStartInvestigation}
            disabled={starting}
            className="btn-primary"
          >
            {starting ? (
              <>
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                Running {aiProvider === "gemini" ? "Gemini" : "Claude"}…
              </>
            ) : (
              <>
                <Play className="w-4 h-4" />
                Start Investigation
              </>
            )}
          </button>
        </div>
      </div>

      {error && (
        <div className="card p-4 border-red-200 bg-red-50 text-red-700 text-sm mb-6">
          {error}
        </div>
      )}

      {starting && (
        <div className="card p-6 border-blue-200 bg-blue-50 mb-6">
          <div className="flex items-center gap-3 mb-1">
            <div className="w-5 h-5 border-2 border-blue-500 border-t-transparent rounded-full animate-spin shrink-0" />
            <p className="font-semibold text-blue-800">Starting investigation…</p>
          </div>
          <p className="text-sm text-blue-600">
            You'll be redirected to the investigation page in a moment.
          </p>
        </div>
      )}

      {/* Alert description banner */}
      {alert.metadata?.description && (
        <div className="card p-4 border-amber-200 bg-amber-50 mb-6">
          <p className="text-sm text-amber-800">{String(alert.metadata.description)}</p>
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
                ["Customer ID",    alert.customer.id],
                ["Occupation",     alert.customer.occupation || "—"],
                ["Nationality",    alert.customer.nationality],
                ["Date of Birth",  alert.customer.date_of_birth || "—"],
                ["Risk Score",     `${alert.customer.risk_score}/100 (${alert.customer.risk_label})`],
              ].map(([label, value]) => (
                <div key={label} className="flex justify-between gap-2">
                  <dt className="text-slate-500">{label}</dt>
                  <dd className={`font-medium text-right ${label === "Risk Score" && alert.customer.risk_score >= 70 ? "text-red-600" : ""}`}>{value}</dd>
                </div>
              ))}
            </dl>
          </div>

          {/* KYC Status */}
          <div className="card p-5">
            <p className="section-title flex items-center gap-2"><Shield className="w-3.5 h-3.5" />KYC & Compliance</p>
            <dl className="space-y-2 text-sm">
              <div className="flex justify-between gap-2">
                <dt className="text-slate-500">KYC Status</dt>
                <dd className={`font-medium ${kycColor(alert.customer.kyc_status)}`}>
                  {kycLabel(alert.customer.kyc_status)}
                </dd>
              </div>
              <div className="flex justify-between gap-2">
                <dt className="text-slate-500">PEP Status</dt>
                <dd className={`font-medium ${alert.customer.is_pep ? "text-red-600" : "text-green-600"}`}>
                  {alert.customer.is_pep ? "⚠️ Politically Exposed Person" : "✓ Clear"}
                </dd>
              </div>
              <div className="flex justify-between gap-2">
                <dt className="text-slate-500">Account Status</dt>
                <dd className={`font-medium capitalize ${alert.account.status === "frozen" || alert.account.status === "dormant" ? "text-red-600" : "text-green-600"}`}>
                  {alert.account.status}
                </dd>
              </div>
            </dl>
          </div>

          {/* Account Info */}
          <div className="card p-5">
            <p className="section-title flex items-center gap-2"><DollarSign className="w-3.5 h-3.5" />Account Details</p>
            <dl className="space-y-2 text-sm">
              {[
                ["Account No.",  alert.account.account_number],
                ["Type",         alert.account.type],
                ["Balance",      formatCurrency(alert.account.balance)],
                ["Currency",     alert.account.currency],
                ["Opened",       alert.account.opened_at || "—"],
                ["Branch",       alert.account.branch || "—"],
              ].map(([label, value]) => (
                <div key={label} className="flex justify-between gap-2">
                  <dt className="text-slate-500">{label}</dt>
                  <dd className="font-medium text-right font-mono text-xs">{value}</dd>
                </div>
              ))}
            </dl>
          </div>

          {/* Risk Indicators */}
          {alert.metadata?.risk_indicators && (alert.metadata.risk_indicators as string[]).length > 0 && (
            <div className="card p-5 border-red-200 bg-red-50">
              <p className="section-title flex items-center gap-2 text-red-600 mb-2">
                <AlertTriangle className="w-3.5 h-3.5" />Risk Indicators
              </p>
              <ul className="space-y-1.5">
                {(alert.metadata.risk_indicators as string[]).map((ind) => (
                  <li key={ind} className="text-xs text-red-700 flex items-start gap-1.5">
                    <span className="mt-0.5 shrink-0">•</span>{ind}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>

        {/* Right Column – Transactions */}
        <div className="lg:col-span-2 space-y-6">

          {/* Transaction Summary */}
          <div className="grid grid-cols-3 gap-4">
            {[
              { label: "Total Inbound",  value: formatCurrency(inboundTotal),  color: "text-emerald-600" },
              { label: "Total Outbound", value: formatCurrency(outboundTotal), color: "text-rose-600" },
              { label: "Pass-Through %", value: `${passthroughRatio}%`,
                color: Number(passthroughRatio) >= 80 ? "text-red-700 font-bold" : "text-slate-900" },
            ].map((stat) => (
              <div key={stat.label} className="card p-4 text-center">
                <p className={`text-xl font-bold ${stat.color}`}>{stat.value}</p>
                <p className="text-xs text-slate-400 mt-0.5">{stat.label}</p>
              </div>
            ))}
          </div>

          {/* Rule & Time Period */}
          <div className="card p-4 border-slate-200 bg-slate-50 text-sm space-y-1">
            <p><span className="text-slate-500">Rule triggered: </span><span className="font-medium">{alert.metadata?.rule_triggered || "—"}</span></p>
            <p><span className="text-slate-500">Period: </span><span className="font-medium">{alert.metadata?.time_period || "—"}</span></p>
          </div>

          {/* Transaction Table */}
          <div className="card overflow-hidden">
            <div className="p-4 border-b border-slate-100">
              <p className="section-title flex items-center gap-2 mb-0">
                <DollarSign className="w-3.5 h-3.5" />Transaction History ({txns.length})
              </p>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-slate-50">
                  <tr>
                    {["Txn ID", "Date", "Type", "Direction", "Amount", "Counterparty / Description"].map((h) => (
                      <th key={h} className="px-4 py-2.5 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {txns.map((txn) => {
                    const inbound = isInbound(txn);
                    const counterparty = txn.counterparty_name || txn.from_account || txn.to_account || txn.description;
                    return (
                      <tr key={txn.id} className="hover:bg-slate-50">
                        <td className="px-4 py-2.5 font-mono text-xs text-slate-500">{txn.id}</td>
                        <td className="px-4 py-2.5 text-slate-600 text-xs">{txn.date}</td>
                        <td className="px-4 py-2.5 text-xs text-slate-500 capitalize">{txn.type.replace(/_/g, " ")}</td>
                        <td className="px-4 py-2.5">
                          <span className={`badge text-xs ${inbound ? "bg-emerald-50 text-emerald-700 border-emerald-200" : "bg-rose-50 text-rose-700 border-rose-200"}`}>
                            {txnDirection(txn)}
                          </span>
                        </td>
                        <td className={`px-4 py-2.5 font-semibold ${inbound ? "text-emerald-700" : "text-rose-700"}`}>
                          {formatCurrency(txn.amount)}
                        </td>
                        <td className="px-4 py-2.5 text-slate-600 text-xs max-w-xs">
                          <p className="truncate">{counterparty}</p>
                          {txn.location && (
                            <p className="text-slate-400 flex items-center gap-1 mt-0.5">
                              <MapPin className="w-2.5 h-2.5" />{txn.location}
                              {txn.counterparty_country && ` · ${txn.counterparty_country}`}
                            </p>
                          )}
                        </td>
                      </tr>
                    );
                  })}
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
                      <span className="badge bg-gray-100 text-gray-600 border-gray-200">{inv.status}</span>
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
