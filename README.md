# 🏛️ CivicGuide — Digital Assistant for Public Services (2030)

> Hackathon project for **"Digital Assistants: Evolution to 2030 (Public Sector)"**
> A next-generation assistant that understands how citizens *actually* talk, translates bureaucratic language into plain language, and guides people step-by-step through public service workflows.

*(Rename "CivicGuide" to your team/project name.)*

---

## 📌 The Challenge

Citizens describe problems in messy, colloquial language ("I just moved and need to sort my papers"). Government services answer with forms, legal terms, and fragmented portals. Our assistant bridges that gap:

1. **Understand** unstructured input — typos, slang, mixed languages, voice.
2. **Translate** administrative/legal text into plain, accessible language — always with a link to the official source.
3. **Guide** the citizen through the full workflow — asks only for missing info, pre-fills forms, lists required documents and deadlines.

**Guiding principles:** trustworthy (cited sources, no invented rules), honest (says "I'm not sure" and hands off to a human), accessible (WCAG, plain language, multilingual), privacy-aware (minimal data, mock data only).

---

## 🎯 Demo Scope (keep it small!)

We focus on **2–3 life events**, done really well:

- [ ] **Scenario 1:** Moving house (address change registration)
- [ ] **Scenario 2:** _TBD — e.g. registering a newborn / starting a small business_
- [ ] **Scenario 3 (stretch):** _TBD_

**Demo "wow" moments:**
- Messy/typo-filled (or voice) request → correctly understood
- Official paragraph vs. our plain-language version, side by side
- Guided checklist with pre-filled form + mock submission
- Edge case → assistant admits uncertainty and offers human contact

---

## 🧱 Tech Stack

| Layer | Technology | Why |
|---|---|---|
| **Frontend** | Vue 3 + Vite + TypeScript | Fast to build, easy to learn |
| **UI** | Tailwind CSS + PrimeVue (or shadcn-vue) | Accessible components out of the box |
| **State / data** | Pinia + fetch / Vercel AI SDK (`@ai-sdk/vue`) | Simple state, streaming chat |
| **Backend** | AdonisJS 7 (API starter kit) + TypeScript | Batteries included: routing, validation (VineJS), ORM, migrations |
| **Database** | PostgreSQL + **pgvector** | Relational data + vector search for RAG in one DB |
| **LLM** | Anthropic Claude API (or OpenAI) via TS SDK | Tool calling + structured JSON outputs |
| **RAG** | Chunked official documents → embeddings → pgvector | Answers grounded in real sources with citations |
| **Workflow engine** | JSON-defined state machines per service | Reliable, deterministic step flow (LLM fills, code decides) |
| **Voice (stretch)** | Web Speech API (browser) | Zero-setup speech-to-text |
| **Hosting** | Vercel/Netlify (web) + Railway/Render (API + Postgres) | Free tiers, deploy in minutes |
| **Tooling** | ESLint + Prettier, GitHub Projects, Docker Compose | Consistent code, local DB in one command |

> **Alternative:** If the team prefers a single app/deploy, use **Nuxt 3** (Vue + server routes) instead of a separate Adonis API.

---

## 🗺️ Architecture

```
 Citizen (text / voice)
        │
        ▼
 ┌──────────────┐     REST / SSE     ┌────────────────────────────────────┐
 │  Vue 3 Web   │ ◄────────────────► │            AdonisJS API            │
 │  Chat + Steps│                    │                                    │
 └──────────────┘                    │ 1. Intent + field extraction (LLM) │
                                     │ 2. RAG retrieval (pgvector)        │
                                     │ 3. Workflow engine (next step)     │
                                     │ 4. Plain-language answer + sources │
                                     │ 5. Tool calls → mock gov services  │
                                     └───────────────┬────────────────────┘
                                                     │
                                ┌────────────────────┼───────────────────┐
                                ▼                    ▼                   ▼
                        PostgreSQL+pgvector     LLM API          Mock Gov APIs
                        (docs, sessions)     (Claude/OpenAI)  (registry, booking)
```

---

## 📁 Repository Structure

```
/
├── web/                  # Vue 3 frontend
│   ├── src/
│   │   ├── components/   # ChatWindow, StepGuide, SourceCard, PlainLangToggle...
│   │   ├── views/
│   │   ├── stores/       # Pinia stores
│   │   └── api/          # API client (typed)
│   └── .env.example
├── api/                  # AdonisJS backend
│   ├── app/
│   │   ├── controllers/  # chat, workflows, documents
│   │   ├── services/     # llm, rag, workflowEngine, mockGov
│   │   └── validators/
│   ├── database/migrations/
│   ├── start/routes.ts
│   └── .env.example
├── data/
│   ├── sources/          # Official PDFs/pages (raw)
│   ├── workflows/        # JSON workflow definitions per service
│   └── scripts/          # ingest.ts — chunk + embed documents
├── docs/                 # Pitch deck, demo script, screenshots
├── docker-compose.yml    # Local Postgres + pgvector
└── README.md
```

---

## 🚀 Getting Started

### ⚡ Quick setup (recommended)
Works on **Linux, macOS and Windows via WSL2** (Ubuntu).

```bash
chmod +x setup.sh
./setup.sh            # interactive menu: All / Core / Frontend / Backend / Database / AI / Extras / Check
./setup.sh --frontend # or pick parts directly; add -y to auto-confirm
./setup.sh --check    # just show what's installed
```

**Windows / WSL users:**
- Run everything **inside the WSL terminal**, not PowerShell.
- Clone the repo inside WSL (`~/projects/...`), **not** under `/mnt/c/...` — that is slow and breaks hot-reload.
- Install **Docker Desktop** on Windows → Settings → Resources → **WSL Integration** → enable your distro.
- In VS Code, install the **WSL** extension and open the project with `code .` from the WSL terminal.
- If you see `/usr/bin/env: 'bash\r'`, fix line endings with `sed -i 's/\r$//' setup.sh`.

The manual steps below do the same thing, if you'd rather do it by hand.

### Prerequisites
- Node.js **20+**
- Docker (for local Postgres)
- An LLM API key (ask the team lead — **never commit keys**)

### 1. Clone & start the database
```bash
git clone <repo-url> && cd <repo>
docker compose up -d        # starts Postgres with pgvector on :5432
```

`docker-compose.yml`:
```yaml
services:
  db:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_USER: hack
      POSTGRES_PASSWORD: hack
      POSTGRES_DB: civicguide
    ports: ["5432:5432"]
```

### 2. Backend (AdonisJS)
```bash
cd api
cp .env.example .env        # fill in keys
npm install
node ace migration:run
npm run ingest              # load + embed documents from /data/sources
node ace serve --hmr        # http://localhost:3333
```

### 3. Frontend (Vue)
```bash
cd web
cp .env.example .env
npm install
npm run dev                 # http://localhost:5173
```

### Environment variables
**api/.env**
```
PORT=3333
APP_KEY=generate-with-node-ace-generate-key
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=hack
DB_PASSWORD=hack
DB_DATABASE=civicguide
LLM_PROVIDER=anthropic
ANTHROPIC_API_KEY=
EMBEDDINGS_API_KEY=
CORS_ORIGIN=http://localhost:5173
```
**web/.env**
```
VITE_API_URL=http://localhost:3333
```

---

## 🔌 API Contract (agree on this in hour 1!)

| Method | Endpoint | Purpose |
|---|---|---|
| `POST` | `/api/chat` | Send a message; streams the assistant reply (SSE) |
| `GET` | `/api/sessions/:id` | Get conversation + current workflow state |
| `POST` | `/api/simplify` | Turn official text into plain language |
| `GET` | `/api/workflows/:service` | Get workflow definition (steps, docs, deadlines) |
| `POST` | `/api/workflows/:service/submit` | Submit pre-filled form to mock gov service |

**Example `/api/chat` response (final JSON):**
```json
{
  "sessionId": "abc123",
  "reply": "Since you moved, you need to register your new address within 3 days...",
  "intent": "address_change",
  "confidence": 0.92,
  "extractedFields": { "newAddress": "Budapest, Fő utca 1.", "moveDate": "2026-10-10" },
  "missingFields": ["idCardNumber"],
  "workflow": { "service": "address_change", "currentStep": 2, "totalSteps": 4 },
  "sources": [{ "title": "Official address registration guide", "url": "https://..." }],
  "handoff": null
}
```

**Workflow definition example (`data/workflows/address_change.json`):**
```json
{
  "service": "address_change",
  "title": "Register a new address",
  "steps": [
    { "id": "collect", "fields": ["fullName", "newAddress", "moveDate", "idCardNumber"] },
    { "id": "documents", "required": ["ID card", "Proof of residence"] },
    { "id": "review" },
    { "id": "submit", "action": "mockGov.registerAddress" }
  ],
  "deadlineDays": 3
}
```

---

## 👥 Team & Roles

| Role | Owner | Responsibilities |
|---|---|---|
| Product / Pitch | _name_ | Scenarios, demo script, slides, scope control |
| AI / LLM | _name_ | Prompts, extraction, plain-language, guardrails |
| Backend / Data | _name_ | Adonis API, RAG ingest, workflow engine, mock APIs |
| Frontend / UX | _name_ | Chat UI, step guide, accessibility, mobile |
| Floater / QA | _name_ | Voice, multilingual, testing, backup demo video |

---

## 🔀 Git Workflow

- `main` is **always deployable** — protected, merge via PR.
- Branch names: `feat/chat-ui`, `fix/rag-citations`, `chore/deploy`.
- Small PRs, merge often (aim for every 1–2 hours). One quick approval is enough.
- Commit style: `feat: add plain-language toggle`, `fix: handle empty input`.
- **Pull `main` before starting new work.** Talk in `#blockers` if you touch someone else's area.
- 🔐 Never commit `.env` files or API keys.

---

## ⏱️ 24-Hour Timeline

| Hours | Milestone | ✅ |
|---|---|---|
| 0–2 | Scope locked, roles assigned, API contract agreed, repo + both deploys live ("hello world") | ☐ |
| 2–8 | Core loop: chat → intent → Scenario 1 guided end-to-end | ☐ |
| 8–14 | RAG + citations, plain-language mode, Scenario 2, UI polish | ☐ |
| 14–18 | Guardrails (confidence + human handoff), accessibility, multilingual | ☐ |
| 18–21 | 🧊 **FEATURE FREEZE** — bug fixes, demo data, edge cases | ☐ |
| 21–24 | Pitch deck, rehearse demo 3×, record backup video, submit | ☐ |

**Sync check-ins every 4 hours (10 min):** done / doing / blocked / what to cut.

---

## ✅ Definition of Done (per feature)

- Works on the **deployed** version, not just locally
- Handles empty / weird input without crashing
- Keyboard accessible & readable on mobile
- No secrets in code

---

## 🎤 Demo Checklist

- [ ] Demo script written (≤ 3 min) and rehearsed
- [ ] Demo data seeded on production
- [ ] Backup video recorded
- [ ] Slides: problem → solution → live demo → tech → impact → 2030 vision
- [ ] Fallback plan if Wi-Fi/LLM API fails (cached responses or video)

---

## 🛡️ Responsible AI Notes

- Answers are grounded in official sources and **always cite them**.
- Low confidence → assistant says so and suggests contacting the office.
- Only **mock/synthetic personal data** used in this prototype.
- Plain-language output targets roughly a B1 reading level.

---

## 📄 License

MIT — built with ☕ at the hackathon.