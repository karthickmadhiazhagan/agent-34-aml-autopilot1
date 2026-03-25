import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Agent 34 – AML Case Autopilot",
  description: "AI-powered AML Case Narrative & Evidence Autopilot",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <div className="min-h-screen flex flex-col">
          {/* Top Navigation */}
          <header className="bg-slate-900 text-white shadow-lg">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <div className="flex items-center justify-between h-16">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 bg-blue-500 rounded-lg flex items-center justify-center font-bold text-sm">
                    34
                  </div>
                  <div>
                    <span className="font-semibold tracking-tight">AML Case Autopilot</span>
                    <span className="ml-2 text-xs text-slate-400 hidden sm:inline">
                      Agent 34 · AI-Powered Investigations
                    </span>
                  </div>
                </div>
                <nav className="flex items-center gap-6 text-sm">
                  <a href="/" className="text-slate-300 hover:text-white transition-colors">
                    Alerts
                  </a>
                  <a href="/investigations" className="text-slate-300 hover:text-white transition-colors">
                    Investigations
                  </a>
                </nav>
              </div>
            </div>
          </header>

          {/* Page Content */}
          <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8">
            {children}
          </main>

          <footer className="border-t border-slate-200 py-4 text-center text-xs text-slate-400">
            Agent 34 – AML Case Narrative & Evidence Autopilot · FinCEN / FATF Regulatory Framework
          </footer>
        </div>
      </body>
    </html>
  );
}
