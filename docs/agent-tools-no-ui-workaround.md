# agentTools[] — No Graphical UI Workaround

## The Problem

When MCP config is wired via `agentTools[]` inside the Agent node (the correct approach for tool calling during reasoning), the Flowise UI does not render a graphical form for it. You cannot visually edit the MCP server URL, auth headers, or selected actions — the entry appears as a collapsed array with no controls.

Wiring via a separate `toolAgentflow` node gives you the full graphical editor, but that model breaks tool calling (see `tool-agent-vs-agent-tools.md`).

---

## Workaround Options

### Option 1 — Edit the JSON directly (always works, most tedious)

1. In Flowise UI: open the flow → kebab menu → **Export**
2. Open the exported JSON in a text editor
3. Find the Agent node's `inputs.agentTools` array and edit:
   - `mcpServerConfig` — JSON string with `url` and `headers`
   - `mcpActions` — JSON array string of tool names to expose
4. Re-import: **Import** → select the edited file → save

```json
"agentTools": [
  {
    "agentSelectedTool": "customMCP",
    "agentSelectedToolConfig": {
      "mcpServerConfig": "{\"url\":\"http://host.docker.internal:8080/verticals/mcp\",\"headers\":{\"Authorization\":\"Basic YWRtaW46YWRtaW4=\",\"Accept\":\"application/json, text/event-stream\"}}",
      "mcpActions": "[\"denodo_verticals_query_financial_customers\",\"denodo_verticals_query_financial_loans\",\"denodo_verticals_query_financial_underwriting\"]"
    }
  }
]
```

---

### Option 2 — Use a `toolAgentflow` node as an editing scratchpad (recommended)

The `toolAgentflow` node has a full graphical editor for MCP config. Use it as a scratchpad — configure visually, copy the values, then paste into the Agent node's JSON. The Tool node does not need to be connected.

**Steps:**

1. Add a `toolAgentflow` node to the canvas (leave it disconnected)
2. Configure it graphically: select `customMCP`, set the MCP server URL, auth headers, and tick the actions you want
3. Export the flow JSON
4. In the JSON, find `toolAgentflow_X.inputs.toolAgentflowSelectedToolConfig` and copy its `mcpServerConfig` and `mcpActions` values
5. Paste those values into the Agent node's `inputs.agentTools[0].agentSelectedToolConfig`
6. Delete the `toolAgentflow` node from the JSON (or leave it on canvas — disconnected nodes don't execute)
7. Re-import

The `toolAgentflow` node acts purely as a UI helper. The actual runtime tool config lives in `agentTools[]`.

---

### Option 3 — Keep a disconnected `toolAgentflow` node on the canvas permanently

Same as Option 2, but keep the Tool node on the canvas indefinitely as a "live config panel". Whenever you need to change MCP actions:

1. Edit the `toolAgentflow` node graphically in the UI
2. Export → copy the updated config values → paste into Agent's `agentTools[]` → re-import

The disconnected node is never executed by the runtime. It's visual scaffolding only.

---

## Quick Reference — Which Values to Sync

When copying from a `toolAgentflow` node to `agentTools[]`, these are the fields that matter:

| `toolAgentflow` node path | → | Agent node path |
|---|---|---|
| `inputs.toolAgentflowSelectedToolConfig.mcpServerConfig` | → | `inputs.agentTools[0].agentSelectedToolConfig.mcpServerConfig` |
| `inputs.toolAgentflowSelectedToolConfig.mcpActions` | → | `inputs.agentTools[0].agentSelectedToolConfig.mcpActions` |

Both values are JSON-encoded strings (a string containing a JSON object/array), not raw JSON — keep the outer quotes and escaping intact.

---

## Reference Flows

| File | Notes |
|---|---|
| `workflows/comparision/agent-flow-single-node-working.json` | Correct `agentTools[]` wiring — edit this JSON directly as per Option 1 |
| `workflows/comparision/agent-flow-single-node-not-working.json` | Has a `toolAgentflow` node with graphical config — use as scratchpad per Option 2 |
