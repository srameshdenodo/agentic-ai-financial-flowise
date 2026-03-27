# Agentflow Tool Wiring: Two Models

## The Problem We Solved

During development we tried two different ways to connect Denodo MCP tools to agents
in Flowise Agentflow. The first approach looked correct visually but silently failed.
The second approach is how Flowise actually works.

---

## Model 1: `toolAgentflow` Edge (Wrong)

### How it looked

```
Start → Credit Analyst → Payment Analyst → Property Analyst → Risk Synthesizer
                                                                       ↓
                                                               Credit Tools ❌
```

All agents ran green (succeeded), then a single tool node fired at the end and timed out.

### What we thought it meant

> Each agent is connected to a tool node via an edge. The agent calls the tool
> during its LLM reasoning turn, gets the data back, then passes results forward.

### What it actually means

The `toolAgentflow` node is a **deterministic flow step** — it executes in the
graph queue like any other node, after all its parent nodes complete. It has
**no connection to the LLM's function-calling mechanism**. The agent's LLM runs
first with zero tools available, produces output (hallucinated or empty), marks
itself complete, then the tool node fires as a separate step with no way to feed
results back to the agent that already finished.

### JSON shape

The tool was a **separate node** in the `nodes` array, wired via **edges**:

```json
// Node definition (sits alongside agents in the flow graph)
{
  "id": "toolAgentflow_0",
  "type": "agentFlow",
  "data": {
    "name": "toolAgentflow",
    "label": "Credit Tools",
    "inputs": {
      "toolAgentflowSelectedTool": "customMCP",
      "toolAgentflowSelectedToolConfig": {
        "mcpServerConfig": "{\"url\":\"...\",\"headers\":{...}}",
        "mcpActions": "[\"denodo_verticals_query_financial_customers\"]"
      },
      "toolInputArgs": [],
      "toolUpdateState": []
    }
  }
}

// Agent node — agentTools is EMPTY
{
  "id": "agentAgentflow_0",
  "data": {
    "name": "agentAgentflow",
    "inputs": {
      "agentTools": [],        // ← LLM has NO tools during reasoning
      ...
    }
  }
}

// Edge connecting agent → tool (defines flow order only)
{
  "id": "agentAgentflow_0-toolAgentflow_0",
  "source": "agentAgentflow_0",
  "target": "toolAgentflow_0",
  "type": "agentFlow"
}
```

### Why it timed out

With 4 tool nodes each initializing their own MCP connection, the StreamableHTTP
handshake overhead (before falling back to SSE) burned through the 60-second
timeout before any real query ran. Even after consolidating to 1 shared tool
node, the fundamental problem remained: agents never called tools, and the single
tool node fired at the end with no arguments.

---

## Model 2: `agentTools` Array (Correct)

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

| Aspect | `toolAgentflow` edge | `agentTools` array |
|---|---|---|
| Where tool config lives | Separate node in flow graph | Inside agent's `inputs` |
| Connected via | Edge (`source → target`) | JSON array in agent inputs |
| When tool executes | After agent completes (flow step) | During agent's LLM turn (inline) |
| LLM sees tool? | No | Yes (as function-calling schema) |
| Result fed back to LLM? | No | Yes |
| Visible in Flowise canvas? | Yes — as a node with a wire | No — embedded, not visualized |
| Configurable in Flowise UI? | Yes | Partially (tool type visible, inner config opaque) |
| Works for autonomous agents? | No | Yes |
| Use case | Deterministic tool call with hardcoded args as a pipeline step | LLM-driven tool calling where the model decides when and how to call |

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
