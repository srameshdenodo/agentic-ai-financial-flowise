# Demo Script — Autonomous Loan Decision Agentflow

**Duration:** ~5 minutes
**Audience:** Financial industry decision-makers, data architects
**Key messages:**
- **Autonomous multi-agent AI** — one trigger, four specialized agents, zero human steering
- **Denodo as a real-time data layer** — every field in the decision brief comes from live data, not a cache
- **Zero-Copy** — no data movement, no ETL, agents query Denodo directly via MCP

---

## Setup Checklist (before the demo)

- [ ] `docker compose up -d` and Flowise is running at `http://localhost:3000`
- [ ] Denodo MCP server running at `http://localhost:8080/verticals/mcp`
- [ ] `workflows/Loan Agent Flow New Agents.json` imported as an **Agentflow** (not Chatflow)
- [ ] OpenAI credential configured and attached to all agent nodes
- [ ] Flowise canvas open in one browser tab — so you can show the visual flow while it runs
- [ ] Chat widget open in another tab (or side-by-side)

---

## The Single Trigger

### Input
> **"Analyze customer 20000 for loan eligibility"**

That is the only message you type. Everything else is autonomous.

---

## What Happens Next (narrate as the thought bubbles appear)

### Agent 1 — Credit Analyst
> *"First agent fires. It's querying Denodo for credit and customer data."*

**Tool calls (visible in Flowise thought bubbles):**
1. `denodo_verticals_get_view_schema` — confirms column names on `financial_underwriting`
2. `denodo_verticals_query_financial_underwriting` — pulls credit score, employment history, financial history for customer 20000
3. `denodo_verticals_query_financial_customers` — pulls loyalty tier, income band, risk classification

**Passes forward:**
```
CREDIT_ANALYSIS
  Credit Score:      810 (STRONG)
  Employment:        Stable — 7+ years same employer
  Financial History: Excellent — no missed payments in 7 years
  Verdict:           STRONG
```

---

### Agent 2 — Payment History Analyst
> *"Agent 1 is done. Agent 2 picks up automatically — no prompt from me."*

**Tool calls:**
1. `denodo_verticals_query_financial_payments` — payment regularity, missed payments, delinquencies
2. `denodo_verticals_query_financial_loans` — existing loan obligations, total debt exposure

**Passes forward:**
```
PAYMENT_ANALYSIS
  Payment Reliability: Consistent — 0 missed payments
  Total Debt Exposure: $500,000
  DTI Flag:            Within acceptable range
  Verdict:             STRONG
```

---

### Agent 3 — Property Analyst
> *"Third agent. It's computing LTV — Loan-to-Value — against the collateral."*

**Tool calls:**
1. `denodo_verticals_query_financial_properties` — property value and type
2. `denodo_verticals_query_financial_loans` — existing liens to compute LTV

**Passes forward:**
```
PROPERTY_ANALYSIS
  Property Value:   $650,000
  LTV Ratio:        76.9% (ACCEPTABLE)
  Collateral Risk:  LOW
  Verdict:          ACCEPTABLE
```

---

### Agent 4 — Risk Synthesizer
> *"Final agent. It reads everything the first three produced and makes the call."*

**Tool calls:**
1. `denodo_verticals_query_financial_rates` — live rate sheet, ordered by rate ASC for best available offer

**Produces the Loan Decision Brief:**

```
==============================
LOAN DECISION BRIEF
==============================
Customer:         Jane Doe | ID: 20000 | Tier: Diamond
Requested Amount: $500,000 | Term: 30 years

CREDIT ANALYSIS
  Credit Score:      810 (STRONG)
  Employment:        Stable — 7+ years same employer
  Financial History: Excellent — no missed payments in 7 years

PAYMENT HISTORY
  Payment Reliability: Consistent — 0 missed payments
  Total Debt Exposure: $500,000
  Missed Payments:     0
  DTI Flag:            Within acceptable range

PROPERTY / COLLATERAL
  Property Value:  $650,000
  LTV Ratio:       76.9% (ACCEPTABLE)
  Collateral Risk: LOW

DECISION
  Outcome:         APPROVE
  Suggested Rate:  6.00% (Mortgage, 30yr)
  Rationale:       Strong credit profile (FICO 810), zero delinquency history,
                   and LTV well below the 90% threshold. All three analyst
                   verdicts are STRONG or ACCEPTABLE.
  Conditions:      None
==============================

This decision brief was produced by 4 specialized agents working autonomously
— each querying Denodo in real-time. Zero data copies, one trigger.
```

---

## Talking Points

**After the brief appears:**

- "I typed one sentence. Four agents ran in sequence, each with a scoped job and scoped data access — exactly like a human underwriting team."
- "Every number in that brief — credit score, LTV, rate — came from a live Denodo query. There is no pre-computed cache."
- "The rate I just quoted is from the live rate sheet. If the rate changes tonight, the next run returns the updated rate automatically."
- "Notice the agents didn't step on each other's data. Credit Analyst can't accidentally query payment history. That's deliberate scoping via MCP tool filtering."

**Point to the Flowise canvas:**

- "This is the visual equivalent of a CrewAI crew — but you can see every agent, every tool connection, every edge in the UI. No code to read."
- "Each node is an independent LLM call with its own system prompt. The state — what Agent 1 found — flows forward as conversation context to Agent 2, 3, and 4."

---

## Contrast with the Chatflow Demo

| | Proactive Retention Chatflow | Loan Decision Agentflow |
|---|---|---|
| Trigger | Human types 3 questions | One sentence |
| Flow | Reactive (you drive it) | Autonomous (agents drive it) |
| Agents | 1 general agent | 4 specialized agents |
| Output | Conversational | Structured decision brief |
| Analogy | Chatbot | Underwriting committee |

> *"The Chatflow was a conversation. This is a process. Same Denodo data layer underneath — completely different interaction model."*

---

## Closing Soundbite

> "What you just saw is four AI specialists — each with their own data access, their own job, their own judgment — collaborating autonomously to produce a credit decision in under 30 seconds. Denodo is the single source of truth they all query. No data lake, no copies, no overnight batch. Just live data, right when the agent needs it."

---

## Fallback Q&A Answers

**Q: What stops an agent from making up data?**
→ Temperature = 0 on all agents. Every field in the brief must come from a tool result. If a tool returns nothing, the agent says so and issues a REFER decision.

**Q: Can you run the agents in parallel instead of sequence?**
→ Sequence is intentional here — Agent 4 needs Agents 1–3's outputs. But Flowise Agentflow supports parallel branches too; you'd add a fork node before independent agents.

**Q: What if customer 20000 doesn't exist?**
→ The Credit Analyst will report no results found. The Risk Synthesizer will issue REFER TO UNDERWRITER citing missing data — as instructed in its system prompt.

**Q: Can this connect to our core banking system instead of Denodo?**
→ Denodo virtualizes whatever sits underneath — core banking, data warehouse, flat files, APIs. The agents don't change; only the Denodo view configuration changes.

**Q: How is this different from a rule-based decisioning engine?**
→ A rules engine applies fixed thresholds. This agent reads the rationale behind the numbers — employment narrative, payment history text, collateral context — and synthesizes judgment, not just a score.
