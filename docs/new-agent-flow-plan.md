# New Agent Flow Plan — Loan Decision Agentflow
## Source: `workflows/Loan Agent Flow New Agents.json`

## What Was Learned from the Working Template

| Property | Correct Value |
|---|---|
| Node React-Flow type | `"agentFlow"` |
| Start node name | `"startAgentflow"` — `startInputType: "chatInput"` |
| Agent node name | `"agentAgentflow"` — category `"Agent Flows"` |
| Tool node name | `"toolAgentflow"` — wraps customMCP |
| inputAnchors | `[]` for all agentFlow nodes |
| Edge type | `"agentFlow"` — targetHandle = node ID only |
| System prompt field | `agentMessages` array with `role: "system"` (NOT `agentUserMessage`) |
| Model config | Inline `agentModelConfig` inside `inputs` — no separate ChatOpenAI node |
| MCP server config | `{"servers": {"Denodo_MCP_server": {url, headers}}}` |

---

## Issues in Current File

| # | Issue | Fix |
|---|---|---|
| 1 | System prompt in `agentUserMessage` (injects as user msg) | Move to `agentMessages[0]` with `role: "system"` |
| 2 | `toolAgentflow_0` has `mcpActions: ""` — no tools selected | Set scoped `mcpActions` per agent |
| 3 | `reasoning: true` on gpt-4o-mini — not supported | Set `reasoning: false` |
| 4 | Missing Property Analyst (agent 3 of 4) | Add `agentAgentflow_2` + `toolAgentflow_2` |
| 5 | Missing Risk Synthesizer (agent 4 of 4) | Add `agentAgentflow_3` + `toolAgentflow_3` |
| 6 | Both agents share one tool node | One scoped tool node per agent |

---

## Target Flow

```
Start → Credit Analyst    → Payment Analyst → Property Analyst → Risk Synthesizer
             ↓                    ↓                  ↓                   ↓
         Tool (credit)       Tool (payment)     Tool (property)    Tool (rates)
```

---

## Tool Scoping per Agent

| Agent | Denodo Tools |
|---|---|
| Credit Analyst | `get_view_schema`, `query_financial_underwriting`, `query_financial_customers`, `run_sql_query`, `validate_sql_query` |
| Payment Analyst | `get_view_schema`, `query_financial_payments`, `query_financial_loans`, `run_sql_query`, `validate_sql_query` |
| Property Analyst | `get_view_schema`, `query_financial_properties`, `query_financial_loans`, `run_sql_query`, `validate_sql_query` |
| Risk Synthesizer | `get_view_schema`, `query_financial_rates`, `run_sql_query` |

---

## Status

- [x] Plan written
- [x] JSON built — `workflows/Loan Agent Flow New Agents.json` (overwritten with full 4-agent flow)
