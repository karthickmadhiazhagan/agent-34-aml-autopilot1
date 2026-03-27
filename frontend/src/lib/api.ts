import type { Alert, AlertSummary, Investigation } from "@/types";

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001";

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: { "Content-Type": "application/json", ...options?.headers },
    ...options,
  });
  if (!res.ok) {
    const error = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(error.error || `HTTP ${res.status}`);
  }
  return res.json();
}

// ─── Alerts ───────────────────────────────────────────────────────────────────
export async function fetchAlerts(): Promise<{ alerts: AlertSummary[]; total: number }> {
  return request("/api/v1/alerts");
}
export async function fetchAlert(alertId: string): Promise<{
  alert: Alert;
  investigations: Array<{ id: number; status: string; created_at: string }>;
}> {
  return request(`/api/v1/alerts/${alertId}`);
}

// ─── Investigations ───────────────────────────────────────────────────────────
export async function fetchInvestigations(): Promise<{ investigations: Investigation[] }> {
  return request("/api/v1/investigations");
}
export async function fetchInvestigation(id: number): Promise<Investigation> {
  return request(`/api/v1/investigations/${id}`);
}
export async function startInvestigation(alertId: string, aiProvider: string = "claude"): Promise<Investigation> {
  return request("/api/v1/investigations", {
    method: "POST",
    body: JSON.stringify({ alert_id: alertId, ai_provider: aiProvider }),
  });
}

// ─── Narrative gate ───────────────────────────────────────────────────────────
export async function approveNarrative(id: number, approvedBy?: string): Promise<{ message: string; investigation: Investigation }> {
  return request(`/api/v1/investigations/${id}/approve_narrative`, {
    method: "POST",
    body: JSON.stringify({ approved_by: approvedBy }),
  });
}
export async function regenerateNarrative(id: number): Promise<{ message: string; investigation: Investigation }> {
  return request(`/api/v1/investigations/${id}/regenerate_narrative`, { method: "POST" });
}
export async function closeInvestigation(id: number, reason?: string): Promise<{ message: string; investigation: Investigation }> {
  return request(`/api/v1/investigations/${id}/close`, {
    method: "POST",
    body: JSON.stringify({ reason }),
  });
}

// ─── SAR gate ─────────────────────────────────────────────────────────────────
export async function approveSar(id: number, approvedBy?: string): Promise<{ message: string; investigation: Investigation }> {
  return request(`/api/v1/investigations/${id}/approve_sar`, {
    method: "POST",
    body: JSON.stringify({ approved_by: approvedBy }),
  });
}
export async function reviseSar(id: number): Promise<{ message: string; investigation: Investigation }> {
  return request(`/api/v1/investigations/${id}/revise_sar`, { method: "POST" });
}

// ─── PDF export ───────────────────────────────────────────────────────────────
export async function downloadSarPdf(id: number, alertId: string): Promise<void> {
  const res = await fetch(`${API_BASE}/api/v1/investigations/${id}/export_pdf`);
  if (!res.ok) {
    const error = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(error.error || `HTTP ${res.status}`);
  }
  const blob = await res.blob();
  const url  = URL.createObjectURL(blob);
  const a    = document.createElement("a");
  a.href     = url;
  a.download = `SAR_${alertId}_${new Date().toISOString().split("T")[0]}.pdf`;
  a.click();
  URL.revokeObjectURL(url);
}

// ─── Formatting helpers ───────────────────────────────────────────────────────
export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(amount);
}
export function severityColor(severity: string): string {
  const m: Record<string, string> = {
    Critical: "bg-red-100 text-red-800 border-red-200",
    High:     "bg-orange-100 text-orange-800 border-orange-200",
    Medium:   "bg-yellow-100 text-yellow-800 border-yellow-200",
    Low:      "bg-green-100 text-green-800 border-green-200",
  };
  return m[severity] || "bg-gray-100 text-gray-800 border-gray-200";
}
export function statusColor(status: string): string {
  const m: Record<string, string> = {
    narrative_ready:    "bg-blue-100 text-blue-800",
    narrative_approved: "bg-indigo-100 text-indigo-800",
    sar_ready:          "bg-amber-100 text-amber-800",
    sar_approved:       "bg-green-100 text-green-800",
    completed:          "bg-green-100 text-green-800",
    running:            "bg-sky-100 text-sky-800",
    pending:            "bg-gray-100 text-gray-600",
    closed:             "bg-slate-100 text-slate-500",
    failed:             "bg-red-100 text-red-800",
  };
  return m[status] || "bg-gray-100 text-gray-600";
}
export function statusLabel(status: string): string {
  const m: Record<string, string> = {
    narrative_ready:    "Narrative Ready — Awaiting Review",
    narrative_approved: "Narrative Approved",
    sar_ready:          "SAR Ready — Awaiting Approval",
    sar_approved:       "SAR Approved ✓",
    running:            "Running Agents…",
    pending:            "Pending",
    closed:             "Closed / Monitor",
    failed:             "Failed",
  };
  return m[status] || status;
}
