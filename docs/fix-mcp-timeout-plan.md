# Fix: MCP Timeout — Consolidate to 1 Shared Tool Node

## Root Cause

Confirmed by reading Flowise source (`core.js`):

1. **Per-call connection overhead**: Every tool call creates a **new MCP client connection** (`createClient()` is called inside each `MCPTool` invocation — not reused).
2. **StreamableHTTP → SSE fallback per connection**: Flowise tries `StreamableHTTPClientTransport` first on every connection. If Denodo doesn't respond to the StreamableHTTP handshake, it hangs until the 60s SDK timeout before falling back to `SSEClientTransport`.
3. **4 independent tool nodes**: Each `toolAgentflow` node initializes its own `MCPToolkit` (calls `tools/list` + new connection per tool call). 4 nodes = 4× the overhead.

Combined, these exceed the 60s outer request timeout before any real work is done.

## Fix

Consolidate 4 tool nodes → 1 shared tool node wired to all 4 agents.

- MCP initializations: 4 → 1
- `tools/list` calls at startup: 4 → 1
- StreamableHTTP→SSE fallback cycles at init: 4 → 1

Scoping is still enforced by each agent's system prompt instructions.

## Changes to `workflows/Loan Agent Flow New Agents.json`

### Nodes
- **Remove**: `toolAgentflow_1`, `toolAgentflow_2`, `toolAgentflow_3`
- **Keep & update**: `toolAgentflow_0` — expand `mcpActions` to all 6 per-view tools

### `toolAgentflow_0` mcpActions
```json
[
  "denodo_verticals_query_financial_customers",
  "denodo_verticals_query_financial_loans",
  "denodo_verticals_query_financial_underwriting",
  "denodo_verticals_query_financial_payments",
  "denodo_verticals_query_financial_properties",
  "denodo_verticals_query_financial_rates"
]
```

### Edges
Remove:
- `agentAgentflow_1 → toolAgentflow_1`
- `agentAgentflow_2 → toolAgentflow_2`
- `agentAgentflow_3 → toolAgentflow_3`

Add:
- `agentAgentflow_1 → toolAgentflow_0`
- `agentAgentflow_2 → toolAgentflow_0`
- `agentAgentflow_3 → toolAgentflow_0`

### Result: 6 nodes, 7 edges
```
Start → Credit ──────────────────┐
                                 ▼
Payment → toolAgentflow_0 (shared)
                                 ▲
Property ────────────────────────┤
                                 ▲
Synthesizer ─────────────────────┘
```

## Status
- [x] Plan written
