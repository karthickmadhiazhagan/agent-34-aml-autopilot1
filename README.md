# Agent 34 – AML Case Narrative & Evidence Autopilot

AI-powered Anti-Money Laundering investigation system that automates evidence collection, pattern analysis, red flag mapping, SAR narrative generation, and QA validation using a 5-agent AI pipeline. Supports both Google Gemini and Anthropic Claude as AI providers.

---

## Tech Stack

| Layer       | Technology                                      |
|-------------|--------------------------------------------------|
| Frontend    | Next.js 14 (App Router + TypeScript)             |
| Backend     | Ruby on Rails 7.1 (API mode)                    |
| Database    | PostgreSQL (10 typologies, 156 transactions, 15 customers) |
| AI Providers | Google Gemini (`gemini-2.5-flash-lite`) · Anthropic Claude (`claude-haiku-4-5-20251001`) |
| Styling     | Tailwind CSS                                    |

---

## Project Structure

```
agent-34-aml-autopilot/
├── backend/                    # Ruby on Rails API (port 3001)
│   ├── app/
│   │   ├── controllers/api/v1/
│   │   │   ├── alerts_controller.rb
│   │   │   └── investigations_controller.rb
│   │   ├── services/
│   │   │   ├── dummy_alert_service.rb         # Simulated AML monitoring data
│   │   │   ├── claude_agent_base.rb           # Base class: API calls, retries, JSON parsing
│   │   │   ├── evidence_collection_agent.rb   # Agent 1 – Evidence Extraction
│   │   │   ├── pattern_analysis_agent.rb      # Agent 2 – AML Pattern Detection
│   │   │   ├── red_flag_mapping_agent.rb      # Agent 3 – FinCEN/FATF Red Flag Mapping
│   │   │   ├── narrative_generation_agent.rb  # Agent 4 – SAR Narrative Writer
│   │   │   ├── qa_validation_agent.rb         # Agent 5 – QA Scorer (0–100)
│   │   │   └── investigation_orchestrator.rb  # Runs all 5 agents in sequence (async)
│   │   └── models/
│   │       └── investigation.rb
│   ├── db/
│   │   ├── schema.rb
│   │   └── seeds.rb                           # Seed data: customers, accounts, transactions, alerts
│   └── config/
│       └── routes.rb
│
└── frontend/                   # Next.js Dashboard (port 3000)
    └── src/
        ├── app/
        │   ├── page.tsx                       # Alert Dashboard
        │   ├── alerts/[id]/page.tsx           # Alert Detail + Start Investigation
        │   ├── investigations/page.tsx        # Investigations List
        │   └── investigations/[id]/
        │       ├── page.tsx                   # Live Pipeline Progress View
        │       ├── narrative/page.tsx         # SAR Narrative Review & Regenerate
        │       └── export/page.tsx            # SAR Export (JSON)
        ├── lib/api.ts                         # API client
        └── types/index.ts                     # TypeScript types
```

---

## AI Agent Pipeline

```
AML Monitoring System (Dummy API)
        ↓
Alert Ingestion (customer + transactions + typology)
        ↓
[Agent 1] Evidence Collection Agent    → Extracts structured evidence from alert data
        ↓
[Agent 2] Pattern Analysis Agent       → Detects AML patterns (pass-through, structuring, etc.)
        ↓
[Agent 3] Red Flag Mapping Agent       → Maps patterns to FinCEN / FATF red flags
        ↓
[Agent 4] Narrative Generation Agent   → Writes full SAR-ready investigation narrative
        ↓
[Agent 5] QA Validation Agent          → Validates narrative accuracy (0–100 score)
        ↓
SAR Output (JSON) → Investigator Review → Approve → File
```

The pipeline runs **asynchronously** in a background thread. The frontend polls every 3 seconds and shows live progress for each agent.

---

## Setup

### Prerequisites

- Ruby 3.2+
- Node.js 18+
- PostgreSQL 14+
- A Google Gemini API key — **free tier available** at [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
- (Optional) An Anthropic Claude API key at [console.anthropic.com](https://console.anthropic.com)

---

### 1. Backend (Rails)

```bash
cd backend

# Copy and configure environment variables
cp .env.example .env
```

Edit `.env` and set your API key(s):

```env
# Google Gemini (free tier — recommended for demo)
GEMINI_API_KEY=your-gemini-api-key-here
GEMINI_MODEL=gemini-2.5-flash-lite

# Anthropic Claude (optional — paid)
ANTHROPIC_API_KEY=your-anthropic-key-here

# AI Mode (see AI Modes section below)
MOCK_AI=false
SMART_AI=true

# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=your_postgres_password
```

Then install dependencies, set up the database, and start the server:

```bash
bundle install

rails db:create db:migrate db:seed

rails server -p 3001
```

The Rails API will be available at `http://localhost:3001`.

> **Seed data includes:** 15 customers, accounts, 156 transactions across 10 AML typologies, and 5 pre-built alerts.

---

### 2. Frontend (Next.js)

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

The dashboard will be available at `http://localhost:3000`.

> The frontend connects to `http://localhost:3001` by default. To change this, edit `frontend/.env.local`:
> ```
> NEXT_PUBLIC_API_URL=http://localhost:3001
> ```

---

## AI Modes

Three modes control how many real API calls are made per investigation:

| Mode | Config | API Calls | Use Case |
|------|--------|-----------|----------|
| **Full Mock** | `MOCK_AI=true` | 0 | Local testing, no API key needed |
| **Smart AI** | `MOCK_AI=false` `SMART_AI=true` | 1 (Agent 4 only) | Demo / cost-efficient production |
| **Full AI** | `MOCK_AI=false` `SMART_AI=false` | 5 (all agents) | Maximum quality output |

**Recommended for demo:** `SMART_AI=true` — only the Narrative agent (Agent 4) calls real AI, reducing token usage by ~80% while still producing a full AI-written SAR narrative.

---

## API Endpoints

### Alerts

| Method | Path               | Description         |
|--------|--------------------|---------------------|
| GET    | /api/v1/alerts     | List all AML alerts |
| GET    | /api/v1/alerts/:id | Get alert by ID     |

**Available Alert IDs:**
- `ALERT_1001` — Unusual Wire Activity (ABC Retail Traders, High)
- `ALERT_1002` — Structuring / Smurfing (John M. Smith, High)
- `ALERT_1003` — High-Volume Cash Deposits (Maria Garcia, Medium)
- `ALERT_1004` — Rapid Pass-Through / Funnel Account (XYZ Import Export, Critical)
- `ALERT_1005` — Multiple Account Transfers (Tech Solutions LLC, Medium)

### Investigations

| Method | Path                                       | Description                        |
|--------|--------------------------------------------|------------------------------------|
| GET    | /api/v1/investigations                    | List all investigations             |
| POST   | /api/v1/investigations                    | Start new investigation (async)     |
| GET    | /api/v1/investigations/:id                | Get investigation status & results  |
| POST   | /api/v1/investigations/:id/approve_narrative | Approve narrative → generate SAR  |
| POST   | /api/v1/investigations/:id/regenerate_narrative | Re-run narrative + QA          |
| POST   | /api/v1/investigations/:id/approve_sar    | Final SAR approval                  |
| POST   | /api/v1/investigations/:id/close          | Close / no action required          |
| GET    | /api/v1/investigations/:id/export_pdf     | Export SAR as PDF                   |

**Start Investigation Example:**
```bash
curl -X POST http://localhost:3001/api/v1/investigations \
  -H "Content-Type: application/json" \
  -d '{"alert_id": "ALERT_1001", "ai_provider": "gemini"}'
```

Response returns immediately with `status: "pending"`. Poll `/api/v1/investigations/:id` until status is `narrative_ready`.

---

## Investigation Status Flow

```
pending → running → narrative_ready → narrative_approved → sar_ready → sar_approved
                                   ↘ (regenerate) ↗              ↘ (revise) ↗
                                                               closed
```

---

## Investigator Workflow

1. Open the dashboard at `http://localhost:3000`
2. Browse incoming AML alerts on the Alert Dashboard
3. Click an alert to view transaction history and customer profile
4. Select AI provider (Gemini or Claude) and click **Start Investigation**
5. Watch the live agent pipeline progress (polls every 3 seconds)
6. Review each agent's output: evidence, patterns, red flags, QA score
7. Read the full AI-generated SAR narrative — regenerate if needed
8. Click **Approve Narrative** → review final SAR output
9. Click **Approve SAR** to file, or **Revise** to loop back
10. Export the structured SAR JSON for regulatory submission

---

## AML Detection Rules

| Rule                       | Trigger Condition                                       |
|----------------------------|---------------------------------------------------------|
| Rapid Pass-Through         | Outbound/Inbound ≥ 90% AND transfer within 24 hours     |
| Funnel Account             | 10+ distinct originators sending to same account        |
| Business Profile Mismatch  | Inbound > 2× expected monthly turnover                 |
| Structuring / Smurfing     | Multiple cash deposits just below $10,000               |
| High-Risk Jurisdiction     | Transactions via BVI, Cayman, Panama, Russia, etc.      |
| PEP / Sanctions Link       | Customer or counterparty linked to PEP or sanctions list|

---

## Troubleshooting

**Gemini 429 Too Many Requests**
The app has built-in retry logic (max 2 retries, up to 60s delay). If you still hit rate limits, switch to `SMART_AI=true` to reduce calls from 5 to 1 per investigation, or use `MOCK_AI=true` for zero API calls.

**Gemini model not found (404)**
Ensure `GEMINI_MODEL=gemini-2.5-flash-lite` in your `.env`. Older models like `gemini-1.5-flash` and `gemini-2.0-flash` have been retired for new users.

**Investigation stuck on "pending"**
Check Rails server logs for errors. The pipeline runs in a background thread — if the thread panics, the investigation will transition to `failed` with an error message shown on the frontend.

**Database connection errors**
Ensure PostgreSQL is running and `DB_USERNAME` / `DB_PASSWORD` in `.env` match your local Postgres setup.

---

## Regulatory References

- **FinCEN** – Financial Crimes Enforcement Network (US Treasury)
- **FATF** – Financial Action Task Force (international AML standards)
- SAR filing complies with 31 U.S.C. § 5318(g) Bank Secrecy Act requirements

---

*Agent 34 – AML Case Narrative & Evidence Autopilot · Training Project*
