# Agent 34 – AML Case Narrative & Evidence Autopilot

AI-powered AML investigation system that automates evidence collection, pattern
analysis, red flag mapping, SAR narrative generation, and QA validation using a
5-agent Anthropic Claude pipeline.

---

## Tech Stack

| Layer       | Technology                          |
|-------------|-------------------------------------|
| Frontend    | Next.js 14 (App Router + TypeScript)|
| Backend     | Ruby on Rails 7.1 (API mode)        |
| AI Agents   | Anthropic Claude API (claude-sonnet-4-6) |
| Database    | SQLite (development)                |
| Styling     | Tailwind CSS                        |

---

## Project Structure

```
agent-34-aml-autopilot/
├── backend/                    # Ruby on Rails API
│   ├── app/
│   │   ├── controllers/api/v1/
│   │   │   ├── alerts_controller.rb
│   │   │   └── investigations_controller.rb
│   │   ├── services/
│   │   │   ├── dummy_alert_service.rb         # Simulated AML monitoring data
│   │   │   ├── claude_agent_base.rb           # Base class for all AI agents
│   │   │   ├── evidence_collection_agent.rb   # Agent 1
│   │   │   ├── pattern_analysis_agent.rb      # Agent 2
│   │   │   ├── red_flag_mapping_agent.rb      # Agent 3
│   │   │   ├── narrative_generation_agent.rb  # Agent 4
│   │   │   ├── qa_validation_agent.rb         # Agent 5
│   │   │   └── investigation_orchestrator.rb  # Runs all agents in sequence
│   │   └── models/
│   │       └── investigation.rb
│   └── config/
│       └── routes.rb
│
└── frontend/                   # Next.js Dashboard
    └── src/
        ├── app/
        │   ├── page.tsx                       # Alert Dashboard
        │   ├── alerts/[id]/page.tsx           # Alert Detail + Start Investigation
        │   ├── investigations/page.tsx        # Investigations List
        │   └── investigations/[id]/
        │       ├── page.tsx                   # Investigation View (agent pipeline)
        │       ├── narrative/page.tsx         # Full SAR Narrative
        │       └── export/page.tsx            # SAR Export
        ├── lib/api.ts                         # API client
        └── types/index.ts                     # TypeScript types
```

---

## AI Agent Pipeline

```
AML Monitoring System (Dummy API)
        ↓
Alert Ingestion
        ↓
[Agent 1] Evidence Collection Agent    → Extracts structured evidence from alert data
        ↓
[Agent 2] Pattern Analysis Agent       → Detects AML patterns (pass-through, structuring, etc.)
        ↓
[Agent 3] Red Flag Mapping Agent       → Maps patterns to FinCEN / FATF red flags
        ↓
[Agent 4] Narrative Generation Agent   → Writes SAR-ready investigation narrative
        ↓
[Agent 5] QA Validation Agent          → Validates narrative accuracy (0–100 score)
        ↓
SAR Output (JSON) → Investigator Review → Approval
```

---

## Setup

### Prerequisites

- Ruby 3.2+
- Node.js 18+
- An Anthropic API key ([get one here](https://console.anthropic.com))

### 1. Backend (Rails)

```bash
cd backend
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY

bundle install
rails db:create db:migrate
rails server -p 3001
```

The Rails API will be available at `http://localhost:3001`.

### 2. Frontend (Next.js)

```bash
cd frontend
cp .env.local.example .env.local
# NEXT_PUBLIC_API_URL=http://localhost:3001 (already set)

npm install
npm run dev
```

The dashboard will be available at `http://localhost:3000`.

---

## API Endpoints

### Alerts (Dummy AML Monitoring System)

| Method | Path                    | Description              |
|--------|-------------------------|--------------------------|
| GET    | /api/v1/alerts          | List all AML alerts      |
| GET    | /api/v1/alerts/:id      | Get alert by ID          |

**Available Alert IDs:**
- `ALERT_1001` — Unusual Wire Activity (ABC Retail Traders, High)
- `ALERT_1002` — Structuring / Smurfing (John M. Smith, High)
- `ALERT_1003` — High-Volume Cash Deposits (Maria Garcia, Medium)
- `ALERT_1004` — Rapid Pass-Through / Funnel Account (XYZ Import Export, Critical)
- `ALERT_1005` — Multiple Account Transfers (Tech Solutions LLC, Medium)

### Investigations

| Method | Path                              | Description                      |
|--------|-----------------------------------|----------------------------------|
| GET    | /api/v1/investigations            | List all investigations           |
| POST   | /api/v1/investigations            | Start new investigation           |
| GET    | /api/v1/investigations/:id        | Get investigation results         |
| POST   | /api/v1/investigations/:id/approve| Approve SAR for filing            |
| GET    | /api/v1/investigations/:id/export | Get SAR structured export         |

**Start Investigation Example:**
```bash
curl -X POST http://localhost:3001/api/v1/investigations \
  -H "Content-Type: application/json" \
  -d '{"alert_id": "ALERT_1001"}'
```

---

## Investigator Workflow

1. Open the dashboard at `http://localhost:3000`
2. Browse incoming AML alerts on the Alert Dashboard
3. Click an alert to view transaction history and customer profile
4. Click **Start Investigation** to run the 5-agent AI pipeline
5. Review each agent's output in the Investigation View
6. Read the full AI-generated SAR narrative
7. Click **Approve SAR** to sign off
8. Download the structured SAR JSON for regulatory filing

---

## AML Detection Rules

| Rule                    | Trigger Condition                                      |
|-------------------------|--------------------------------------------------------|
| Rapid Pass-Through      | Outbound/Inbound ≥ 90% AND transfer within 24 hours    |
| Funnel Account          | 10+ distinct originators to same account               |
| Business Profile Mismatch | Inbound > 2× expected monthly turnover              |
| Structuring / Smurfing  | Multiple cash deposits just below $10,000              |
| High-Risk Jurisdiction  | Transactions via BVI, Cayman, Panama, Russia, etc.     |
| PEP / Sanctions Link    | Customer or counterparty linked to PEP / sanctions     |

---

## Regulatory References

- **FinCEN** – Financial Crimes Enforcement Network (US Treasury)
- **FATF** – Financial Action Task Force (international AML standards)
- SAR filing complies with 31 U.S.C. § 5318(g) Bank Secrecy Act requirements

---

*Agent 34 – AML Case Narrative & Evidence Autopilot · Training Project*
