# Demo Script — Intelligent Wealth & Risk Concierge

**Duration:** ~10 minutes
**Audience:** Financial industry decision-makers, data architects
**Key messages:**
- Denodo as a **Vector-Enabled Semantic Layer** — structured + unstructured, one platform
- **Zero-Copy**: no data movement to a separate vector database
- **Real-Time**: live data, no ETL, no stale caches

---

## Setup Checklist (before the demo)

- [ ] `docker compose up -d` and Flowise is running at `http://localhost:3000`
- [ ] Denodo MCP server is running at `http://localhost:8080/verticals/mcp`
- [ ] Flow imported and MCP tools are discovered (Flowise → Settings → Tools → shows Denodo tools)
- [ ] OpenAI credential configured in Flowise UI
- [ ] Chat widget is open and ready
- [ ] Browser zoom is comfortable for the audience to see thought bubbles

---

## Question 1 — Surface the Risk

### Input
> **"Are there any Diamond or Gold tier customers who have complained recently about their rates? Give me their names and current situation."**

### What the Agent Does (Flowise Thought Bubbles)
1. **Tool call:** `denodo_verticals_query_customer_complaints` — filters `sentiment IN ('Negative','Critical')` on customers with `loyalty_level IN ('Gold','Diamond')`
2. **Tool call:** `denodo_verticals_query_financial_customers` — retrieves profile for customer(s) found
3. **Tool call:** `denodo_verticals_query_financial_loans` — pulls active loan details (amount, rate, product type)

### Expected Output (Sample)
```
I found 1 high-risk VIP customer flagged by complaint sentiment analysis:

**Customer:** Jane Doe | **Tier:** Private | **Loyalty:** Diamond
**Complaint (via Denodo semantic search):** "My mortgage rate is way too high. Competitor B offered me 6.2%. I'm seriously considering switching."
**Current Loan:** $500,000 mortgage at 7.50% interest (Active)
**Credit Score:** 810

→ Narrating to audience: "This complaint text was searched semantically — directly inside Denodo. No data was copied to a separate vector database."
```

### Talking Points
- "The agent just performed a **vector similarity search on complaint text** — and it ran entirely inside Denodo."
- "No separate embedding store. No Pinecone, no Weaviate. Denodo is the semantic layer."
- "This is **real-time** — the moment a complaint lands in the system, the agent can find it."

---

## Question 2 — Go Deeper (Unstructured Intelligence)

### Input
> **"What did Jane Doe say in her last meeting with us? Pull the transcript."**

### What the Agent Does (Flowise Thought Bubbles)
1. **Tool call:** `denodo_verticals_query_officer_transcripts` — semantic search for Jane Doe's most recent interaction
2. Returns the meeting summary and key quotes

### Expected Output (Sample)
```
**Meeting:** Branch visit — March 24, 2026 | RM: Sarah Chen

**Transcript Summary:**
Jane expressed frustration with her current mortgage rate of 7.50%.
She mentioned that Competitor B offered her a rate of 6.2% on a comparable 30-year mortgage.
She stated she would begin refinancing paperwork "next month" if we don't respond.
Her credit score was confirmed at 810 with no missed payments in 7 years.

**Key Quote:**
"I've been a Diamond customer for six years. I expect better. Competitor B called me last week with 6.2%. Match it or I'm gone."

→ Narrating to audience: "This transcript lived in an unstructured text store — Denodo exposed it as a queryable tool via MCP, with semantic similarity on the embedding column."
```

### Talking Points
- "The agent just **read a meeting transcript** that was never in a structured database."
- "Denodo virtualizes both worlds: rows in a database AND unstructured text with embeddings."
- "The relationship manager didn't have to file a ticket or run a report. The AI agent found this in seconds."

---

## Question 3 — The Retention Offer

### Input
> **"What's the best offer we can make Jane Doe right now to keep her? Give me a specific recommendation."**

### What the Agent Does (Flowise Thought Bubbles)
1. **Tool call:** `denodo_verticals_query_financial_rates` — filters by tier = 'Private' and product_type = 'Mortgage'
2. **Tool call:** `denodo_verticals_run_sql_query` — joins `financial_products` to confirm eligibility (credit score ≥ 810 qualifies for floor rate)
3. Synthesizes: competitive intel (6.2% from transcript) vs. our best offer vs. credit profile

### Expected Output (Sample)
```
---
**Customer:** Jane Doe | **Tier:** Private | **Loyalty:** Diamond
**Risk Signal:** Churn probability 84% — open complaint, competitor rate offer received
**What She Told Us:** "Competitor B offered me 6.2%. Match it or I'm gone." (March 24 meeting)
**Current Rate:** 7.50% on $500k mortgage
**Best Offer:** 6.00% — Private tier floor rate, eligible based on FICO 810 + 7-year clean payment history
**Recommended Action:** RM Sarah Chen to call Jane within 24 hours with a formal rate-match offer at 6.00%, framed as a Diamond loyalty reward. Prepare a 5-year rate lock option as a secondary hook.
---

→ Narrating to audience: "The rate I just quoted is live — Denodo pulled it directly from the rate sheet system. No ETL, no overnight batch. Zero latency, zero copy."
```

### Talking Points
- "Three data sources — a complaints store, a meeting transcript archive, and a live rate sheet — unified by Denodo."
- "The agent beat the competitor's offer by 0.2%. It found that headroom by checking our **real-time** Private tier floor rate."
- "Zero-Copy: Denodo federated all of this without moving a single byte to an intermediate store."
- "This entire investigation took the agent under 30 seconds. A human analyst would need hours across five systems."

---

## Closing Soundbite

> "What you just saw is Denodo acting as the **intelligence substrate** — the platform that lets AI agents reason over your entire data estate: structured, unstructured, real-time, historical. No data copies. No stale pipelines. Just the data, exactly where it is, when you need it."

---

## Fallback Q&A Answers

**Q: What if the MCP server is down?**
→ The agent will say "tool returned no results" — it won't hallucinate. This is by design (temperature = 0).

**Q: Can this work with other LLMs?**
→ Yes. Swap the ChatOpenAI node for any LLM that supports tool calling (Claude, Gemini, Mistral). The Denodo MCP tools are model-agnostic.

**Q: Is the vector search accurate enough for production?**
→ Denodo's embedding column leverages the same model used at write time. Cosine similarity is computed in-database — same quality as a dedicated vector store, zero infrastructure overhead.

**Q: What about data security?**
→ Denodo enforces row-level and column-level security at the virtualization layer. The agent only sees what the authenticated user is authorized to see — credentials are passed via the MCP header.
