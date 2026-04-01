"use client";

import { useEffect, useState } from "react";
import { fetchAlerts, formatCurrency, severityColor } from "@/lib/api";
import type { AlertSummary } from "@/types";
import Link from "next/link";

export default function AlertDashboard() {
  const [alerts, setAlerts] = useState<AlertSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchAlerts()
      .then(({ alerts }) => setAlerts(alerts))
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const severityUpper = (s: string) =>
    s.charAt(0).toUpperCase() + s.slice(1).toLowerCase();

  return (
    <div>
      <h1 className="text-xl font-bold mb-1">AML Alert Dashboard</h1>
      <p className="text-sm text-gray-500 mb-4">
        {alerts.length} alert(s) loaded. Select an alert to start an AI-assisted investigation.
      </p>

      {loading && <p className="text-gray-500">Loading alerts…</p>}

      {error && (
        <div className="border border-red-400 bg-red-50 text-red-700 p-3 text-sm mb-4">
          <strong>Failed to load alerts:</strong> {error}
          <br />
          <span className="text-xs">Make sure the Rails backend is running on port 3001.</span>
        </div>
      )}

      {!loading && !error && (
        <table className="w-full border-collapse border border-gray-300 text-sm">
          <thead className="bg-gray-100">
            <tr>
              <th className="border border-gray-300 px-3 py-2 text-left">Alert ID</th>
              <th className="border border-gray-300 px-3 py-2 text-left">Severity</th>
              <th className="border border-gray-300 px-3 py-2 text-left">Customer</th>
              <th className="border border-gray-300 px-3 py-2 text-left">Alert Type</th>
              <th className="border border-gray-300 px-3 py-2 text-left">Amount</th>
              <th className="border border-gray-300 px-3 py-2 text-left">Risk Score</th>
              <th className="border border-gray-300 px-3 py-2 text-left">Date</th>
            </tr>
          </thead>
          <tbody>
            {alerts.map((alert) => (
              <tr key={alert.alert_id} className="hover:bg-gray-50">
                <td className="border border-gray-300 px-3 py-2">
                  <Link href={`/alerts/${alert.alert_id}`} className="text-blue-600 hover:underline font-mono text-xs">
                    {alert.alert_id}
                  </Link>
                </td>
                <td className="border border-gray-300 px-3 py-2">
                  <span className={`badge ${severityColor(severityUpper(alert.severity))}`}>
                    {severityUpper(alert.severity)}
                  </span>
                </td>
                <td className="border border-gray-300 px-3 py-2 font-medium">{alert.customer.name}</td>
                <td className="border border-gray-300 px-3 py-2 text-gray-600">{alert.alert_type}</td>
                <td className="border border-gray-300 px-3 py-2">{formatCurrency(alert.total_amount)}</td>
                <td className="border border-gray-300 px-3 py-2">{alert.customer.risk_score}</td>
                <td className="border border-gray-300 px-3 py-2 text-gray-500">
                  {new Date(alert.created_at).toLocaleDateString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
