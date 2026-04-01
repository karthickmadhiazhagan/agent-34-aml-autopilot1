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
          <header className="border-b border-gray-300 bg-white">
            <div className="max-w-5xl mx-auto px-4 py-3 flex items-center justify-between">
              <span className="font-bold text-gray-900">AML Case Autopilot</span>
              <nav className="flex gap-6 text-sm">
                <a href="/" className="text-blue-600 hover:underline">Alerts</a>
                <a href="/investigations" className="text-blue-600 hover:underline">Investigations</a>
              </nav>
            </div>
          </header>

          {/* Page Content */}
          <main className="flex-1 max-w-5xl w-full mx-auto px-4 py-6">
            {children}
          </main>
        </div>
      </body>
    </html>
  );
}
