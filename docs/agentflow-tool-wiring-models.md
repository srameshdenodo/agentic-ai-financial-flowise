# Agentflow Tool Wiring: Three Models

## The Problem We Solved

During development we tried three different ways to connect Denodo MCP tools to agents
in Flowise Agentflow. The first two approaches looked correct visually but silently
failed. The third approach is how Flowise actually works.

---

## Model 1: `toolAgentflow` — 1-to-1 Per-Agent Tool Nodes (Wrong)

### What we built

Four separate tool nodes, one per agent, with 1-to-1 edges. We also had
agent-to-agent edges for sequential execution.

```
Edges in the JSON:
  agent0 → tool0      (Credit Tools)
  agent1 → tool1      (Payment Tools)
  agent2 → tool2      (Property Tools)
  agent3 → tool3      (Rate Tools)

  agent0 → agent1 → agent2 → agent3   (sequential)
```

### What we expected

```
Credit Analyst → [calls Credit Tools] → Payment Analyst → [calls Payment Tools]
               → Property Analyst → [calls Property Tools] → Risk Synthesizer
               → [calls Rate Tools] → Loan Decision Brief
```

Each agent fires its tool, gets results, passes enriched context to the next agent.

### What actually happened

```
Start → Credit Analyst ✅ → Payment Analyst ✅ → Property Analyst ✅ → Risk Synthesizer ✅
                                                                              ↓
                                                                      Credit Tools ❌
```

All agents ran green (no data), then only ONE tool fired at the very end and timed out.

### Why execution order was wrong

Flowise Agentflow uses a **dependency graph queue**. A node executes as soon as all
its parent nodes have completed. Given our edges:

- `agent1` depends on `agent0` → ready after agent0 completes
- `tool0` also depends on `agent0` → also ready after agent0 completes
- Both enter the queue at the same time, but `agent1` is processed first
- `agent2` becomes ready after `agent1`, and so on

So the actual execution order was:

```
agent0 → [agent1 and tool0 both queued] → agent1 runs first →
[agent2 and tool1 both queued] → agent2 runs first → ... →
all agents complete → tools run last
```

The tools always lost the race to the next agent. And even if a tool ran "between"
agents, its output had no path back into the agent that had already finished.

### JSON shape

```json
// 4 separate tool nodes in the nodes array
{ "id": "toolAgentflow_0", "data": { "name": "toolAgentflow", "label": "Credit Tools", ... } }
{ "id": "toolAgentflow_1", "data": { "name": "toolAgentflow", "label": "Payment Tools", ... } }
{ "id": "toolAgentflow_2", "data": { "name": "toolAgentflow", "label": "Property Tools", ... } }
{ "id": "toolAgentflow_3", "data": { "name": "toolAgentflow", "label": "Rate Tools", ... } }

// 8 edges total: 4 agent→agent + 4 agent→tool
{ "source": "agentAgentflow_0", "target": "agentAgentflow_1" }
{ "source": "agentAgentflow_1", "target": "agentAgentflow_2" }
{ "source": "agentAgentflow_2", "target": "agentAgentflow_3" }
{ "source": "agentAgentflow_0", "target": "toolAgentflow_0" }
{ "source": "agentAgentflow_1", "target": "toolAgentflow_1" }
{ "source": "agentAgentflow_2", "target": "toolAgentflow_2" }
{ "source": "agentAgentflow_3", "target": "toolAgentflow_3" }
```

---

## Model 1b: Shared `toolAgentflow` Node (Also Wrong)

To reduce MCP connection overhead, we consolidated to a single tool node wired to
all 4 agents, hoping one shared node would be available to each during their turn.

```
Edges: all 4 agents → toolAgentflow_0 (shared)
       agent0 → agent1 → agent2 → agent3 (sequential)
```

Same problem, worse result. All agents still ran without tools, then the single
shared tool node fired once at the end and timed out. Sharing didn't change the
execution model — it just meant only one tool entry appeared in the execution tree
instead of four.

---

## Model 3: `agentTools` Array (Correct)

### How it looks

```
Start → Credit Analyst → Payment Analyst → Property Analyst → Risk Synthesizer
          (MCP tools        (MCP tools        (MCP tools        (MCP tools
           inside)           inside)           inside)           inside)
```

Each agent's thought bubble shows live tool calls to Denodo during its turn.
No separate tool nodes. No timeout.

### What it actually means

The `agentTools` array inside the agent's `inputs` is what Flowise passes to the
LLM as **function-calling tools**. When the LLM decides to call a tool, Flowise
invokes the MCP connection inline, gets the result, feeds it back to the LLM, and
the LLM continues reasoning — all within the agent's single execution turn.

This is standard LLM function calling (OpenAI tool_calls), just wired to MCP.

### JSON shape

No separate tool node. The MCP config lives **inside the agent's inputs**:

```json
{
  "id": "agentAgentflow_0",
  "data": {
    "name": "agentAgentflow",
    "label": "Credit Analyst",
    "inputs": {
      "agentTools": [              // ← LLM gets these as callable functions
        {
          "agentSelectedTool": "customMCP",
          "agentSelectedToolConfig": {
            "mcpServerConfig": "{\"url\":\"http://host.docker.internal:8080/verticals/mcp\",\"headers\":{\"Authorization\":\"Basic YWRtaW46YWRtaW4=\",\"Accept\":\"application/json, text/event-stream\"}}",
            "mcpActions": "[\"denodo_verticals_query_financial_customers\",\"denodo_verticals_query_financial_loans\",\"denodo_verticals_query_financial_underwriting\"]"
          }
        }
      ],
      "agentModel": "chatOpenAI",
      "modelName": "gpt-4o",
      "temperature": "0",
      ...
    },
    "credential": "15acbf28-1c2b-4ea4-b596-c6dcb11a6cb9"
  }
}
```

No edges to tool nodes. No tool nodes at all.

---

## Side-by-Side Comparison

| Aspect | Model 1: 1-to-1 tool nodes | Model 1b: shared tool node | Model 2: `agentTools` array |
|---|---|---|---|
| Tool config lives in | Separate nodes in graph | Single shared node | Inside each agent's `inputs` |
| Connected via | Edges (agent → tool) | Edges (all agents → 1 tool) | JSON array in agent inputs |
| Nodes in JSON | 4 agents + 4 tools = 8 | 4 agents + 1 tool = 5 | 4 agents only = 4 |
| Execution order | All agents first, tools after | All agents first, tool last | Tool called inline per agent |
| LLM sees tool? | No | No | Yes (function-calling schema) |
| Result fed back to LLM? | No | No | Yes |
| Visible on canvas? | Yes — wired nodes | Yes — wired node | No — embedded |
| Works for autonomous agents? | No | No | Yes |
| Timeout risk | High (4 MCP inits at end) | Lower (1 MCP init) but still fails | None (connection per agent turn, lazy) |

---

## MCP Connection Fix (Accept Header)

Independently of the wiring model, Denodo's MCP server requires:

```
Accept: application/json, text/event-stream
```

on the StreamableHTTP POST. Without it, Denodo returns 400 and Flowise's SSE
fallback also fails (it needs a session ID from the POST first), resulting in a
60-second timeout per connection attempt.

The fix is in `mcpServerConfig.headers`:

```json
{
  "url": "http://host.docker.internal:8080/verticals/mcp",
  "headers": {
    "Authorization": "Basic YWRtaW46YWRtaW4=",
    "Accept": "application/json, text/event-stream"
  }
}
```

This was required regardless of which wiring model is used.
