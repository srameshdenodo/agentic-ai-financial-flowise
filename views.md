# Denodo View Schemas

Database: `verticals`
MCP endpoint: `http://localhost:8080/verticals/mcp`
Tool naming: `denodo_verticals_query_<view_name>` (per-view) + `denodo_verticals_run_sql_query` (arbitrary SQL)

---

## 1. `financial_customers`
Core customer master record.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| name | VARCHAR | Full name |
| email | VARCHAR | Contact email |
| tier | VARCHAR | Segment: `Retail`, `Premium`, `Private` |
| loyalty_level | VARCHAR | `Standard`, `Silver`, `Gold`, `Diamond` |
| credit_score | INTEGER | FICO score (300–850) |
| relationship_manager | VARCHAR | Assigned RM name |
| onboarding_date | DATE | Customer since |

**Sample:**
| id | name | tier | loyalty_level | credit_score | relationship_manager |
|----|------|------|---------------|-------------|----------------------|
| 501 | Jane Doe | Private | Diamond | 810 | Sarah Chen |
| 502 | Bob Martin | Premium | Gold | 740 | James Wu |

---

## 2. `financial_loans`
Active and historical loan records.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| customer_id | INTEGER | FK → financial_customers.id |
| product_type | VARCHAR | `Mortgage`, `Personal`, `Auto`, `Business` |
| amount | DECIMAL | Principal amount |
| rate | DECIMAL | Annual interest rate (%) |
| term_months | INTEGER | Loan term |
| status | VARCHAR | `Active`, `Paid`, `Defaulted` |
| origination_date | DATE | Loan start date |
| maturity_date | DATE | Loan end date |

**Sample:**
| id | customer_id | product_type | amount | rate | status |
|----|-------------|-------------|--------|------|--------|
| 1001 | 501 | Mortgage | 500000 | 7.50 | Active |
| 1002 | 502 | Personal | 25000 | 9.20 | Active |

---

## 3. `financial_accounts`
Deposit and investment accounts.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| customer_id | INTEGER | FK → financial_customers.id |
| account_type | VARCHAR | `Checking`, `Savings`, `Investment`, `Money Market` |
| balance | DECIMAL | Current balance |
| currency | VARCHAR | ISO 4217 (default: USD) |
| opened_date | DATE | Account open date |
| status | VARCHAR | `Active`, `Dormant`, `Closed` |

---

## 4. `financial_transactions`
Transaction ledger (recent 90 days for performance).

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| account_id | INTEGER | FK → financial_accounts.id |
| type | VARCHAR | `Credit`, `Debit`, `Transfer`, `Fee` |
| amount | DECIMAL | Transaction amount |
| description | VARCHAR | Merchant / narrative |
| transaction_date | DATE | Transaction date |
| category | VARCHAR | `Payroll`, `Utilities`, `Investment`, etc. |

---

## 5. `financial_rates`
Current product rate sheet (updated daily).

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| product_type | VARCHAR | `Mortgage`, `Personal`, `Auto`, `Business` |
| tier | VARCHAR | Customer tier (`Retail`, `Premium`, `Private`) |
| current_rate | DECIMAL | Best available rate (%) |
| floor_rate | DECIMAL | Minimum rate floor (%) |
| effective_date | DATE | Rate effective from |
| expiry_date | DATE | Rate valid until |

**Sample:**
| product_type | tier | current_rate | effective_date |
|-------------|------|-------------|----------------|
| Mortgage | Private | 6.00 | 2026-03-01 |
| Mortgage | Premium | 6.45 | 2026-03-01 |
| Personal | Retail | 8.75 | 2026-03-01 |

---

## 6. `financial_products`
Product catalog with eligibility rules.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| name | VARCHAR | Product name |
| category | VARCHAR | `Loan`, `Deposit`, `Investment`, `Insurance` |
| min_rate | DECIMAL | Minimum rate floor |
| max_rate | DECIMAL | Maximum rate ceiling |
| min_credit_score | INTEGER | Minimum FICO required |
| eligible_tiers | VARCHAR | Comma-separated eligible tiers |
| description | VARCHAR | Product description |

---

## 7. `financial_risk_metrics`
AI-computed risk signals (refreshed every 24h).

| Column | Type | Description |
|--------|------|-------------|
| customer_id | INTEGER | FK → financial_customers.id |
| risk_score | DECIMAL | 0–100 (higher = riskier) |
| churn_probability | DECIMAL | 0–1 likelihood of churn within 90 days |
| credit_risk_flag | BOOLEAN | TRUE if credit deterioration detected |
| last_updated | TIMESTAMP | When signals were last computed |
| signal_notes | VARCHAR | Human-readable risk narrative |

**Sample:**
| customer_id | risk_score | churn_probability | signal_notes |
|-------------|-----------|------------------|--------------|
| 501 | 72 | 0.84 | High rate complaint + competitor inquiry detected |

---

## 8. `financial_positions`
Investment portfolio positions (as of prior trading day).

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| customer_id | INTEGER | FK → financial_customers.id |
| asset_class | VARCHAR | `Equity`, `Fixed Income`, `Cash`, `Alternative` |
| instrument | VARCHAR | Ticker or fund name |
| quantity | DECIMAL | Units held |
| market_value | DECIMAL | Current market value (USD) |
| as_of_date | DATE | Valuation date |

---

## 9. `customer_complaints` ⚡ Vector-Enabled
Complaint records with embedded text for semantic search.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| customer_id | INTEGER | FK → financial_customers.id |
| channel | VARCHAR | `Phone`, `Email`, `Branch`, `App` |
| text | TEXT | Full complaint text |
| sentiment | VARCHAR | `Positive`, `Neutral`, `Negative`, `Critical` |
| category | VARCHAR | `Rates`, `Service`, `Fees`, `Product` |
| embedding | VECTOR | Text embedding for semantic similarity search |
| status | VARCHAR | `Open`, `In Progress`, `Resolved` |
| created_at | TIMESTAMP | Complaint submission time |
| resolved_at | TIMESTAMP | Resolution time (nullable) |

> **Zero-Copy demo note:** The `embedding` column enables vector similarity search directly in Denodo — no data movement to a separate vector database.

**Sample:**
| id | customer_id | sentiment | category | text |
|----|-------------|-----------|----------|------|
| 9001 | 501 | Critical | Rates | "My mortgage rate is way too high. Competitor B offered me 6.2%. I'm seriously considering switching." |

---

## 10. `officer_transcripts` ⚡ Vector-Enabled
Meeting notes and call transcripts with semantic search.

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| customer_id | INTEGER | FK → financial_customers.id |
| officer_id | VARCHAR | Relationship manager ID |
| officer_name | VARCHAR | RM name |
| meeting_type | VARCHAR | `Branch Visit`, `Phone Call`, `Video`, `Email` |
| text | TEXT | Full transcript / meeting notes |
| summary | TEXT | AI-generated summary |
| embedding | VECTOR | Text embedding for semantic similarity search |
| meeting_date | DATE | Date of interaction |
| created_at | TIMESTAMP | Record creation time |

> **Zero-Copy demo note:** Semantic similarity search on `embedding` lets the agent find relevant transcripts without a separate RAG pipeline.

**Sample:**
| id | customer_id | officer_name | meeting_date | summary |
|----|-------------|-------------|-------------|---------|
| 7501 | 501 | Sarah Chen | 2026-03-24 | "Customer expressed frustration with current mortgage rate. Mentioned Competitor B offered 6.2% on a comparable product. Asked us to match or she will refinance next month." |

---

## Useful Cross-View Queries

```sql
-- VIP customers with active complaints + high churn risk
SELECT c.name, c.loyalty_level, c.credit_score,
       rm.churn_probability, rm.signal_notes,
       cc.text AS complaint_text
FROM financial_customers c
JOIN financial_risk_metrics rm ON c.id = rm.customer_id
JOIN customer_complaints cc ON c.id = cc.customer_id
WHERE c.loyalty_level IN ('Gold','Diamond')
  AND rm.churn_probability > 0.7
  AND cc.sentiment IN ('Negative','Critical')
  AND cc.status = 'Open'
ORDER BY rm.churn_probability DESC;

-- Best rate we can offer a specific customer
SELECT p.name, fr.current_rate
FROM financial_customers c
JOIN financial_rates fr ON fr.tier = c.tier AND fr.product_type = 'Mortgage'
JOIN financial_products p ON p.category = 'Loan' AND p.min_credit_score <= c.credit_score
WHERE c.id = 501;
```
