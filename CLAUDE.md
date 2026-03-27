# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

An agentic AI workflow system for the financial industry. The system orchestrates AI agents through n8n workflows, using Denodo as a virtualized data layer accessed via MCP (Model Context Protocol).

## Architecture

```
User / Financial Application
        │
        ▼
   n8n Workflows
   (orchestration layer)
        │
        ├──► AI Agent Models (LLMs — e.g., Claude)
        │         │
        │         └──► Tools / Function Calls
        │
        └──► Denodo (via MCP)
                  │
                  └──► Underlying Data Sources
                       (databases, APIs, data lakes)
```

### Key Components

- **n8n**: The workflow engine. Defines the agentic flow — triggers, routing logic, agent node configuration, and tool wiring.
- **AI Agent Models**: LLMs invoked from n8n agent nodes. Receive financial context, reason over it, and decide which tools to call.
- **MCP (Model Context Protocol)**: The integration layer between n8n and Denodo. Exposes Denodo views/queries as callable tools that agents can invoke.
- **Denodo**: Data virtualization platform that federates underlying financial data sources (market data, risk, positions, reference data, etc.) and exposes them as a unified semantic layer.

### Data Flow

1. A trigger (API call, schedule, event) starts an n8n workflow.
2. n8n passes context to an AI agent node (with system prompt + financial task).
3. The agent reasons about the task and calls Denodo tools via MCP to fetch data.
4. Denodo virtualizes and returns data from underlying sources.
5. The agent produces a result; n8n routes it to the next workflow step or output.

## Technology Stack

| Layer | Technology |
|---|---|
| Workflow orchestration | n8n |
| Agent / LLM | Claude (Anthropic) or compatible |
| Data virtualization | Denodo |
| Tool protocol | MCP (Model Context Protocol) |
| Target domain | Financial industry |

## Running the Stack

```bash
# 1. Copy env template and fill in values
cp .env.example .env

# 2. Start n8n
docker compose up -d

# 3. Open n8n UI
# http://localhost:5678

# 4. Import a workflow
# n8n UI → Workflows → Import from file → select a file from workflows/

# 5. Configure OpenAI credential in n8n UI
# Settings → Credentials → New → OpenAI API → paste OPENAI_API_KEY

# 6. Configure Denodo MCP credential in n8n UI
# Settings → Credentials → New → Header Auth
#   Name (header):  Authorization
#   Value: Basic YWRtaW46YWRtaW4=        ← base64 of admin:admin
# The workflow references this credential as "Header Auth account" on the "MCP Client" node

# 7. Activate the workflow and open the chat UI (chat bubble icon)
```

## Context Map

```
CLAUDE.md                                       # This file — project guidance for Claude Code (self-reference for Sentinel)
workflows/                                      # Flowise flow JSON exports (import via Flowise UI)
  Proactive Retention agent Chatflow.json     # Chatflow — conversational retention demo (Tool Calling Agent + MCP + memory)
  Loan Decision Agentflow.json                # Agentflow — autonomous loan decision (4 Sequential Agents, single trigger)
  Loan Agent Flow New Agents.json            # Agentflow — current version with 1 shared tool node (fixes MCP timeout)
agents/                                       # Agent system prompts
  retention-agent-system-prompt.md            # System prompt for the proactive retention agent (source of truth)
  loan-decision/                              # System prompts for the 4 loan decision sub-agents
    credit-analyst-prompt.md                  # Agent 1: credit score + customer profile
    payment-history-prompt.md                 # Agent 2: payment reliability + debt load
    property-analyst-prompt.md                # Agent 3: property valuation + LTV
    risk-synthesizer-prompt.md                # Agent 4: final decision + Loan Decision Brief
demo/demo-script.md                           # 3-question demo walkthrough with talking points
demo/data-setup.sql                           # INSERT statements to seed Jane Doe demo data in the underlying DB
docs/implementation_plan.md                   # Loan Decision Agentflow design and architecture
views.md                                      # Denodo view schemas (reference)
```

## MCP / Denodo Integration

- **MCP server:** `http://localhost:8080/verticals/mcp` (already running, HTTP transport)
- **Database name:** `verticals`
- Tool naming convention: `denodo_verticals_<action>_<view_name>` (e.g. `denodo_verticals_query_financial_loans`)
- The MCP Client node (`mcpClientTool` typeVersion 1.2) in n8n connects via `endpointUrl: http://host.docker.internal:8080/verticals/mcp` using `authentication: headerAuth`
- Rancher Desktop provides `host.docker.internal` automatically — no `extra_hosts` needed in docker-compose
- All 10 financial views are exposed as per-view query tools plus `denodo_verticals_run_sql_query` for arbitrary joins
- When adding a new Denodo view to the demo, tag it with `mcp.tools.view-tag` in Denodo to auto-expose it as a tool

## Key Design Decisions

- **Temperature = 0** on the LLM to ensure deterministic, data-grounded responses (no hallucination)
- **Window Buffer Memory** (20 turns) gives the agent conversation history so follow-up questions work
- The agent system prompt hard-codes the briefing sequence and risk signal rules so the agent behaves consistently across demos
- `VECTOR_DISTANCE(embedding, '<text>')` is used for semantic search on complaints and transcripts; syntax: `VECTOR_DISTANCE(<vector_col>, <text> [, <metric>])` returns a double (lower = more similar, default metric = cosine)
