# toolAgentflow vs agentTools — Wiring Models in Flowise Agentflow

## The Problem

Both wiring approaches look similar in the Flowise UI and use the same MCP/tool config, but only one allows the agent to actually call tools during its reasoning loop. Using the wrong model causes the browser to hang and freeze.

---

## Two Wiring Models

### Model A — `toolAgentflow` edge (broken for tool calling)

```
Start → Agent ──edge──► toolAgentflow node (MCP)
```

The `toolAgentflow` node is a **separate canvas node** wired downstream of the Agent via a graph edge.

**What actually happens at runtime:**
1. Agent runs with `agentTools: ""` (empty — no tools bound)
2. Agent's system prompt instructs it to call tools (e.g. `query_financial_customers`)
3. LLM emits `tool_call` requests — but Flowise has no tools registered to fulfil them
4. Flowise enters a wait state it cannot exit → **browser hangs / freezes**
5. The `toolAgentflow` node never executes meaningfully because the agent never completes

The `toolAgentflow` node connected via an edge runs as a **sequential downstream step after the agent finishes** — it is not callable by the agent during reasoning.

### Model B — `agentTools[]` array (working)

```
Start → Agent (MCP config baked into agentTools[])
```

The MCP config is embedded directly inside the Agent node's `inputs.agentTools` array.

**What actually happens at runtime:**
1. Flowise registers the MCP actions as callable tools on the agent before it starts
2. Agent reasons, emits `tool_call` → Flowise fulfils it → agent gets results
3. Agent continues reasoning with real data → produces output → completes normally

---

## Side-by-Side JSON Comparison

### Not-working (edge wiring)

Agent node — `agentTools` is empty:
```json
"inputs": {
  "agentModel": "chatOpenAI",
  "agentTools": "",
  ...
}
```

Separate `toolAgentflow_0` node holds the MCP config:
```json
{
  "name": "toolAgentflow",
  "inputs": {
    "toolAgentflowSelectedTool": "customMCP",
    "toolAgentflowSelectedToolConfig": {
      "mcpServerConfig": "{\"url\":\"http://host.docker.internal:8080/verticals/mcp\",...}",
      "mcpActions": "[\"denodo_verticals_query_financial_customers\",...]"
    }
  }
}
```

Edge connecting them:
```json
{
  "source": "agentAgentflow_1",
  "target": "toolAgentflow_0"
}
```

### Working (agentTools wiring)

MCP config baked into the Agent node — no separate Tool node, no edge:
```json
"inputs": {
  "agentModel": "chatOpenAI",
  "agentTools": [
    {
      "agentSelectedTool": "customMCP",
      "agentSelectedToolConfig": {
        "mcpServerConfig": "{\"url\":\"http://host.docker.internal:8080/verticals/mcp\",...}",
        "mcpActions": "[\"denodo_verticals_query_financial_customers\",...]"
      }
    }
  ],
  ...
}
```

---

## Rule of Thumb

| Intent | Use |
|---|---|
| Agent calls tool **during** its reasoning loop | `agentTools[]` inside the Agent node |
| Run a tool as a fixed **sequential step after** the agent | `toolAgentflow` node connected via edge |
| Agent has dynamic tool choice (picks from many) | `agentTools[]` with multiple entries |

> **If your agent's system prompt instructs it to call tools, those tools MUST be wired via `agentTools[]`. Wiring them as a downstream `toolAgentflow` edge node will cause the workflow to hang.**

---

## Reference Flows

| File | Wiring model | Result |
|---|---|---|
| `workflows/comparision/agent-flow-single-node-not-working.json` | `toolAgentflow` edge | Hangs — agent has no callable tools |
| `workflows/comparision/agent-flow-single-node-working.json` | `agentTools[]` array | Works — MCP tools bound to agent |
