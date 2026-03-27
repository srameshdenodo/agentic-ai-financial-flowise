# Implementation Plan — Autonomous Loan Decision Agentflow

## Goal

Replace the turn-by-turn chatflow demo with a single-trigger autonomous multi-agent flow:
> **"Help me analyze if I can give a loan to this customer"**
→ Runs 4 specialized sub-agents autonomously → Produces a structured Loan Decision Brief.

---

## Why This Is Different from the Chatflow

| | Proactive Retention Chatflow | Loan Decision Agentflow |
|---|---|---|
| Trigger | Human types each question | Single trigger message |
| Flow | Reactive (human-driven) | Autonomous (agent-driven) |
| Agents | 1 general agent | 4 specialized sub-agents |
| Output | Conversational answer | Structured decision brief |
| Analogy | Chatbot | CrewAI crew |

---

## Architecture

```
[User Trigger]
"Analyze customer 20000 for loan eligibility"
        │
        ▼
[Orchestrator / Supervisor]
Decomposes task, routes to sub-agents in sequence
        │
        ├──► [Agent 1: Credit Analyst]
        │    Tools: financial_underwriting, financial_customers
        │    Output: credit score, history, risk band
        │
        ├──► [Agent 2: Payment History Analyst]
        │    Tools: financial_payments, financial_loans
        │    Output: payment record, delinquency flags, DTI estimate
        │
        ├──► [Agent 3: Property Analyst]
        │    Tools: financial_properties, financial_loans
        │    Output: LTV ratio, property valuation, collateral quality
        │
        └──► [Agent 4: Risk Synthesizer]
             Tools: financial_rates (reads best rate tier)
             Input: outputs from Agents 1–3
             Output: APPROVE / DECLINE / REFER + rationale + suggested rate
                    │
                    ▼
             [Loan Decision Brief]
```

---

## Flowise Implementation

**Flow type:** Sequential Agents (Agentflow, not Chatflow)
- Visual canvas in Flowise with 6 nodes: Start → Agent 1 → Agent 2 → Agent 3 → Agent 4 → End
- Each agent node has its own system prompt and scoped Denodo MCP tools
- State is passed forward via the conversation thread between nodes
- Single LLM (ChatOpenAI, temperature=0) shared across all nodes

**File:** `workflows/Loan Decision Agentflow.json`

---

## Sub-Agent Responsibilities

### Agent 1 — Credit Analyst (`agents/loan-decision/credit-analyst-prompt.md`)
- Queries `financial_underwriting` for credit score, employment history, financial history
- Queries `financial_customers` for loyalty tier, income band, risk weighting
- Outputs: credit score band, employment stability rating, financial history summary

### Agent 2 — Payment History Analyst (`agents/loan-decision/payment-history-prompt.md`)
- Queries `financial_payments` for payment regularity, missed payments, delinquencies
- Queries `financial_loans` for existing loan obligations (total exposure)
- Outputs: payment reliability score, total debt obligation, DTI flag

### Agent 3 — Property Analyst (`agents/loan-decision/property-analyst-prompt.md`)
- Queries `financial_properties` for property value, type, location
- Queries `financial_loans` to compute LTV ratio against existing liens
- Outputs: estimated LTV, collateral quality rating, property risk notes

### Agent 4 — Risk Synthesizer (`agents/loan-decision/risk-synthesizer-prompt.md`)
- Reads all prior agent outputs from conversation state
- Queries `financial_rates` to find the best available rate for the customer's tier
- Synthesizes into a final decision: APPROVE / DECLINE / REFER
- Outputs: structured Loan Decision Brief

---

## Loan Decision Brief Format

```
==============================
LOAN DECISION BRIEF
==============================
Customer:         [Name] | ID: [id] | Tier: [loyalty]
Requested Amount: [amount] | Product: [type] | Term: [years]

CREDIT ANALYSIS
  Credit Score:      [score] ([band])
  Employment:        [stability]
  Financial History: [summary]

PAYMENT HISTORY
  Payment Reliability: [score/flag]
  Existing Obligations: $[total] | DTI: [%]
  Missed Payments:     [count]

PROPERTY / COLLATERAL
  Property Value:  $[value]
  LTV Ratio:       [%]
  Collateral Risk: [LOW / MEDIUM / HIGH]

DECISION
  Outcome:         [APPROVE / DECLINE / REFER TO UNDERWRITER]
  Suggested Rate:  [%] ([loan_type], [term]yr)
  Rationale:       [2–3 sentence justification]
  Conditions:      [any conditions on approval]
==============================
```

---

## Denodo Views Used per Agent

| Agent | Views |
|---|---|
| Credit Analyst | `financial_underwriting`, `financial_customers` |
| Payment History | `financial_payments`, `financial_loans` |
| Property Analyst | `financial_properties`, `financial_loans` |
| Risk Synthesizer | `financial_rates` (read-only, no writes) |

---

## Files to Create

- [ ] `docs/implementation_plan.md` — this file
- [ ] `agents/loan-decision/credit-analyst-prompt.md`
- [ ] `agents/loan-decision/payment-history-prompt.md`
- [ ] `agents/loan-decision/property-analyst-prompt.md`
- [ ] `agents/loan-decision/risk-synthesizer-prompt.md`
- [ ] `workflows/Loan Decision Agentflow.json`
- [ ] Update `CLAUDE.md` Context Map

---

## Status

- [x] Plan written
- [x] Sub-agent prompts written
- [x] Agentflow JSON built
- [x] CLAUDE.md updated
