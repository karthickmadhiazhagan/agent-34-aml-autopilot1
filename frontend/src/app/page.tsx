"use client";

import { useEffect, useState } from "react";
import { fetchAlerts, formatCurrency, severityColor } from "@/lib/api";
import type { AlertSummary } from "@/types";
import { AlertTriangle, ArrowRight, Shield, TrendingUp, TrendingDown } from "lucide-react";
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

  const stats = {
    total: alerts.length,
    critical: alerts.filter((a) => a.severity === "Critical").length,
    high: alerts.filter((a) => a.severity === "High").length,
  };

  return (
    <div>
      {/* Page Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900">AML Alert Dashboard</h1>
        <p className="text-slate-500 mt-1">
          Incoming alerts from the AML monitoring system. Select an alert to begin an AI-assisted investigation.
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
            <Shield className="w-5 h-5 text-blue-600" />
          </div>
          <div>
            <p className="text-2xl font-bold">{stats.total}</p>
            <p className="text-xs text-slate-500">Total Alerts</p>
          </div>
        </div>
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
            <AlertTriangle className="w-5 h-5 text-red-600" />
          </div>
          <div>
            <p className="text-2xl font-bold text-red-600">{stats.critical}</p>
            <p className="text-xs text-slate-500">Critical</p>
          </div>
        </div>
        <div className="card p-4 flex items-center gap-3">
          <div className="w-10 h-10 bg-orange-100 rounded-lg flex items-center justify-center">
            <AlertTriangle className="w-5 h-5 text-orange-500" />
          </div>
          <div>
            <p className="text-2xl font-bold text-orange-600">{stats.high}</p>
            <p className="text-xs text-slate-500">High Priority</p>
          </div>
        </div>
      </div>

      {/* Alert List */}
      {loading && (
        <div className="card p-12 text-center text-slate-400">
          <div className="inline-block w-8 h-8 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin mb-3" />
          <p>Loading alerts from AML monitoring system…</p>
        </div>
      )}

      {error && (
        <div className="card p-6 border-red-200 bg-red-50 text-red-700">
          <p className="font-semibold">Failed to load alerts</p>
          <p className="text-sm mt-1">{error}</p>
          <p className="text-xs mt-2 text-red-500">Make sure the Rails backend is running on port 3001.</p>
        </div>
      )}

      {!loading && !error && (
        <div className="card divide-y divide-slate-100">
          {alerts.map((alert) => (
            <Link
              key={alert.alert_id}
              href={`/alerts/${alert.alert_id}`}
              className="flex items-center gap-4 p-5 hover:bg-slate-50 transition-colors group"
            >
              {/* Severity Badge */}
              <div className={`badge ${severityColor(alert.severity)} shrink-0`}>
                {alert.severity}
              </div>

              {/* Alert Info */}
              <div className="flex-1 min-w-0">
                <div className="flex items-baseline gap-2">
                  <span className="font-semibold text-slate-900 truncate">{alert.customer_name}</span>
                  <span className="text-xs text-slate-400 shrink-0">{alert.alert_id}</span>
                </div>
                <p className="text-sm text-slate-500 mt-0.5">{alert.alert_type}</p>
              </div>

              {/* Transaction Amounts */}
              <div className="hidden sm:flex gap-6 text-sm shrink-0">
                <div className="text-right">
                  <div className="flex items-center gap-1 text-emerald-600 justify-end">
                    <TrendingUp className="w-3.5 h-3.5" />
                    <span className="font-medium">{formatCurrency(alert.total_inbound)}</span>
                  </div>
                  <p className="text-xs text-slate-400">Inbound</p>
                </div>
                <div className="text-right">
                  <div className="flex items-center gap-1 text-rose-600 justify-end">
                    <TrendingDown className="w-3.5 h-3.5" />
                    <span className="font-medium">{formatCurrency(alert.total_outbound)}</span>
                  </div>
                  <p className="text-xs text-slate-400">Outbound</p>
                </div>
              </div>

              {/* Date */}
              <div className="hidden lg:block text-right text-sm text-slate-400 shrink-0 w-24">
                {alert.alert_generated_date}
              </div>

              <ArrowRight className="w-4 h-4 text-slate-300 group-hover:text-blue-500 transition-colors shrink-0" />
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
