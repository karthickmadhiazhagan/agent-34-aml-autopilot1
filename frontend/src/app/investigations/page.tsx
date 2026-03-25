"use client";

import { useEffect, useState } from "react";
import { fetchInvestigations, statusColor } from "@/lib/api";
import type { Investigation } from "@/types";
import { ArrowRight, Search } from "lucide-react";
import Link from "next/link";

export default function InvestigationsPage() {
  const [investigations, setInvestigations] = useState<Investigation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchInvestigations()
      .then(({ investigations }) => setInvestigations(investigations))
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900">Investigations</h1>
        <p className="text-slate-500 mt-1">All AI-assisted AML investigations.</p>
      </div>

      {loading && (
        <div className="card p-12 text-center text-slate-400">
          <div className="inline-block w-8 h-8 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin mb-3" />
          <p>Loading investigations…</p>
        </div>
      )}

      {error && (
        <div className="card p-6 border-red-200 bg-red-50 text-red-700">{error}</div>
      )}

      {!loading && !error && investigations.length === 0 && (
        <div className="card p-16 text-center">
          <Search className="w-10 h-10 text-slate-300 mx-auto mb-3" />
          <p className="font-semibold text-slate-500">No investigations yet</p>
          <p className="text-sm text-slate-400 mt-1">Start one from an alert page.</p>
          <Link href="/" className="btn-primary mt-4 inline-flex">View Alerts</Link>
        </div>
      )}

      {!loading && !error && investigations.length > 0 && (
        <div className="card divide-y divide-slate-100">
          {investigations.map((inv) => (
            <Link
              key={inv.id}
              href={`/investigations/${inv.id}`}
              className="flex items-center gap-4 p-5 hover:bg-slate-50 transition-colors group"
            >
              <div>
                <div className="flex items-baseline gap-2">
                  <span className="font-semibold text-slate-900">Investigation #{inv.id}</span>
                  <span className="text-xs text-slate-400">{inv.alert_id}</span>
                </div>
                <p className="text-sm text-slate-500 mt-0.5">
                  {new Date(inv.created_at).toLocaleString()}
                </p>
              </div>
              <div className="ml-auto flex items-center gap-3">
                {inv.approved && (
                  <span className="badge bg-emerald-100 text-emerald-800 border-emerald-200 text-xs">
                    ✓ SAR Approved
                  </span>
                )}
                <span className={`badge ${statusColor(inv.status)} text-xs`}>{inv.status}</span>
                <ArrowRight className="w-4 h-4 text-slate-300 group-hover:text-blue-500 transition-colors" />
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
