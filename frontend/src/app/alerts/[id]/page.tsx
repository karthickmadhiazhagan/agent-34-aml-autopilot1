"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { fetchAlert, startInvestigation, formatCurrency, severityColor } from "@/lib/api";
import type { Alert, Transaction } from "@/types";
import Link from "next/link";

function isInbound(txn: Transaction): boolean {
  if (txn.type === "cash_deposit" || txn.type === "crypto_conversion") return true;
  if (txn.type === "cash_withdrawal") return false;
  return txn.from_account === null;
}

function kycLabel(status: string) {
  const map: Record<string, string> = {
    verified: "Verified",
    pending: "Pending",
    failed: "Failed",
    enhanced_due_diligence: "EDD Required",
  };
  return map[status] || status;
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

  if (loading) return <p className="text-gray-500">Loading alert details…</p>;

  if (error && !alert) {
    return <div className="border border-red-400 bg-red-50 text-red-700 p-3 text-sm">{error}</div>;
  }

  if (!alert) return null;

  const txns = alert.transactions || [];
  const inboundTotal  = txns.filter(isInbound).reduce((s, t) => s + t.amount, 0);
  const outboundTotal = txns.filter(t => !isInbound(t)).reduce((s, t) => s + t.amount, 0);
  const passthroughRatio = inboundTotal > 0 ? ((outboundTotal / inboundTotal) * 100).toFixed(1) : "0";
  const severityLabel = alert.severity.charAt(0) + alert.severity.slice(1).toLowerCase();

  return (
    <div>
      <Link href="/" className="text-blue-600 hover:underline text-sm">&larr; Back to Alerts</Link>

      {/* Header */}
      <div className="mt-4 mb-6 flex items-start justify-between gap-4">
        <div>
          <div className="flex items-center gap-3 mb-1">
            <span className={`badge ${severityColor(severityLabel)}`}>{severityLabel}</span>
            <span className="text-sm text-gray-400 font-mono">{alert.alert_id}</span>
          </div>
          <h1 className="text-xl font-bold">{alert.customer.name}</h1>
          <p className="text-gray-500 text-sm">{alert.alert_type}</p>
        </div>

        <div className="flex items-center gap-2 shrink-0">
          <select
            value={aiProvider}
            onChange={(e) => setAiProvider(e.target.value as "claude" | "gemini")}
            disabled={starting}
            className="text-sm border border-gray-300 px-3 py-2 bg-white"
          >
            <option value="gemini">Gemini Flash (Google)</option>
            <option value="claude">Claude (Anthropic)</option>
          </select>
          <button onClick={handleStartInvestigation} disabled={starting} className="btn-primary">
            {starting ? `Running ${aiProvider}…` : "Start Investigation"}
          </button>
        </div>
      </div>

      {error && (
        <div className="border border-red-400 bg-red-50 text-red-700 p-3 text-sm mb-4">{error}</div>
      )}

      {alert.metadata?.description && (
        <div className="border border-yellow-400 bg-yellow-50 p-3 text-sm text-yellow-800 mb-4">
          {String(alert.metadata.description)}
        </div>
      )}

      {/* Two-column layout */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* Left: Customer / KYC / Account */}
        <div className="space-y-4">

          <div>
            <p className="section-title">Customer Profile</p>
            <table className="w-full text-sm border-collapse">
              <tbody>
                {[
                  ["Customer ID",   alert.customer.id],
                  ["Occupation",    alert.customer.occupation || "—"],
                  ["Nationality",   alert.customer.nationality],
                  ["Date of Birth", alert.customer.date_of_birth || "—"],
                  ["Risk Score",    `${alert.customer.risk_score}/100 (${alert.customer.risk_label})`],
                ].map(([label, value]) => (
                  <tr key={String(label)} className="border-b border-gray-100">
                    <td className="py-1 pr-3 text-gray-500 w-1/2">{label}</td>
                    <td className="py-1 font-medium">{value}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div>
            <p className="section-title">KYC &amp; Compliance</p>
            <table className="w-full text-sm border-collapse">
              <tbody>
                <tr className="border-b border-gray-100">
                  <td className="py-1 pr-3 text-gray-500">KYC Status</td>
                  <td className="py-1 font-medium">{kycLabel(alert.customer.kyc_status)}</td>
                </tr>
                <tr className="border-b border-gray-100">
                  <td className="py-1 pr-3 text-gray-500">PEP Status</td>
                  <td className="py-1 font-medium">{alert.customer.is_pep ? "Politically Exposed Person" : "Clear"}</td>
                </tr>
                <tr className="border-b border-gray-100">
                  <td className="py-1 pr-3 text-gray-500">Account Status</td>
                  <td className="py-1 font-medium capitalize">{alert.account.status}</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div>
            <p className="section-title">Account Details</p>
            <table className="w-full text-sm border-collapse">
              <tbody>
                {[
                  ["Account No.", alert.account.account_number],
                  ["Type",        alert.account.type],
                  ["Balance",     formatCurrency(alert.account.balance)],
                  ["Currency",    alert.account.currency],
                  ["Opened",      alert.account.opened_at || "—"],
                  ["Branch",      alert.account.branch || "—"],
                ].map(([label, value]) => (
                  <tr key={String(label)} className="border-b border-gray-100">
                    <td className="py-1 pr-3 text-gray-500">{label}</td>
                    <td className="py-1 font-medium font-mono text-xs">{value}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {alert.metadata?.risk_indicators && (alert.metadata.risk_indicators as string[]).length > 0 && (
            <div>
              <p className="section-title">Risk Indicators</p>
              <ul className="text-sm text-red-700 space-y-1 list-disc ml-4">
                {(alert.metadata.risk_indicators as string[]).map((ind) => (
                  <li key={ind}>{ind}</li>
                ))}
              </ul>
            </div>
          )}
        </div>

        {/* Right: Transactions */}
        <div className="lg:col-span-2 space-y-4">

          {/* Summary row */}
          <div className="text-sm border border-gray-200 p-3 flex gap-6">
            <span>Inbound: <strong className="text-green-700">{formatCurrency(inboundTotal)}</strong></span>
            <span>Outbound: <strong className="text-red-700">{formatCurrency(outboundTotal)}</strong></span>
            <span>Pass-through: <strong className={Number(passthroughRatio) >= 80 ? "text-red-700" : ""}>{passthroughRatio}%</strong></span>
          </div>

          {/* Rule / Period */}
          <div className="text-sm text-gray-600 border border-gray-200 p-3">
            <span className="text-gray-400">Rule: </span>{alert.metadata?.rule_triggered || "—"}
            &nbsp;&nbsp;
            <span className="text-gray-400">Period: </span>{alert.metadata?.time_period || "—"}
          </div>

          {/* Transaction Table */}
          <div>
            <p className="section-title">Transaction History ({txns.length})</p>
            <div className="overflow-x-auto">
              <table className="w-full border-collapse border border-gray-300 text-sm">
                <thead className="bg-gray-100">
                  <tr>
                    {["Txn ID", "Date", "Type", "Direction", "Amount", "Counterparty / Notes"].map((h) => (
                      <th key={h} className="border border-gray-300 px-2 py-1.5 text-left text-xs">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {txns.map((txn) => {
                    const inbound = isInbound(txn);
                    const counterparty = txn.counterparty_name || txn.from_account || txn.to_account || txn.description;
                    return (
                      <tr key={txn.id} className="hover:bg-gray-50">
                        <td className="border border-gray-200 px-2 py-1.5 font-mono text-xs text-gray-500">{txn.id}</td>
                        <td className="border border-gray-200 px-2 py-1.5 text-xs">{txn.date}</td>
                        <td className="border border-gray-200 px-2 py-1.5 text-xs capitalize">{txn.type.replace(/_/g, " ")}</td>
                        <td className="border border-gray-200 px-2 py-1.5 text-xs font-medium">
                          <span className={inbound ? "text-green-700" : "text-red-700"}>
                            {inbound ? "In" : "Out"}
                          </span>
                        </td>
                        <td className={`border border-gray-200 px-2 py-1.5 font-medium text-xs ${inbound ? "text-green-700" : "text-red-700"}`}>
                          {formatCurrency(txn.amount)}
                        </td>
                        <td className="border border-gray-200 px-2 py-1.5 text-xs text-gray-600">
                          {counterparty}
                          {txn.location && ` · ${txn.location}`}
                          {txn.counterparty_country && ` (${txn.counterparty_country})`}
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
            <div>
              <p className="section-title">Previous Investigations</p>
              <table className="w-full border-collapse border border-gray-300 text-sm">
                <thead className="bg-gray-100">
                  <tr>
                    <th className="border border-gray-300 px-3 py-1.5 text-left">ID</th>
                    <th className="border border-gray-300 px-3 py-1.5 text-left">Status</th>
                    <th className="border border-gray-300 px-3 py-1.5 text-left">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {investigations.map((inv) => (
                    <tr key={inv.id} className="hover:bg-gray-50">
                      <td className="border border-gray-200 px-3 py-1.5">
                        <Link href={`/investigations/${inv.id}`} className="text-blue-600 hover:underline">
                          #{inv.id}
                        </Link>
                      </td>
                      <td className="border border-gray-200 px-3 py-1.5 text-gray-600">{inv.status}</td>
                      <td className="border border-gray-200 px-3 py-1.5 text-gray-500 text-xs">
                        {new Date(inv.created_at).toLocaleDateString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
