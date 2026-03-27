-- =============================================================
-- DEMO DATA SETUP — Intelligent Wealth & Risk Concierge
-- Generated: 2026-03-26
-- =============================================================
-- Run these INSERTs against the UNDERLYING source database that
-- backs Denodo's virtual views (e.g. PostgreSQL, MySQL, etc.).
-- Denodo will reflect changes immediately — no ETL needed.
--
-- IMPORTANT: Adjust table names to match your underlying source
-- if they differ from the Denodo view names.
--
-- Execute sections IN ORDER (1 → 7) to satisfy foreign key deps.
-- =============================================================
--
-- ⚠️  SCHEMA GAPS — reviewed against live Denodo MCP on 2026-03-26
--
-- GAP 1: 'Diamond' is not a current loyalty_classification value.
--        Current values: Silver, Gold, Platinum.
--        → If a CHECK constraint exists, drop or extend it first (see Section 2).
--
-- GAP 2: Loan status 'active' does not exist.
--        Current values: pending, approved, rejected.
--        → If a CHECK constraint exists, extend it (see Section 3).
--          Alternatively, change 'active' to 'approved' — the agent will
--          then report "approved" instead of "Active" in the demo output.
--
-- GAP 3: financial_rates has no 'tier' or 'product_type' column.
--        Only columns: rate_id, loan_type, term, interest_rate.
--        → Adding loan_type='Mortgage' at 6.00% so the agent can find
--          a mortgage-specific rate to recommend as the counter-offer.
--          The agent discovers the schema dynamically and will use loan_type
--          to distinguish Mortgage from Fixed rates.
--
-- GAP 4: customer_complaints has no 'sentiment' column.
--        → The agent will search complaint_text via LIKE (per CLAUDE.md).
--          The complaint text below is written to be clearly findable via
--          keywords: "rate", "competitor", "switching", "Diamond".
--
-- GAP 5: embedding columns (VECTOR<FLOAT>) in customer_complaints and
--        officer_transcripts are inserted as NULL here.
--        → If the Denodo MCP server performs vector similarity search,
--          generate embeddings using the same model as existing rows and
--          UPDATE these rows. For LIKE-based demo queries, NULL is fine.
-- =============================================================


-- =============================================================
-- SECTION 1: Add Sarah Chen as Loan Officer (required before Section 3)
-- =============================================================
-- No Sarah Chen exists in financial_loanofficers.
-- max loan_officer_id = 1000 → using 1001.

INSERT INTO financial_loanofficers (loan_officer_id, first_name, last_name, email, phone_number)
VALUES (1001, 'Sarah', 'Chen', 'sarah.chen@bank.com', '555-200-1001');


-- =============================================================
-- SECTION 2: Add Jane Doe as a Diamond-tier customer
-- =============================================================
-- max customer_id = 19999 → using 20000.
-- ⚠️ GAP 1: 'Diamond' is a new loyalty_classification value.
--
-- If a CHECK constraint exists, update it first. Example for PostgreSQL:
--   ALTER TABLE financial_customers DROP CONSTRAINT IF EXISTS ck_loyalty_classification;
--   ALTER TABLE financial_customers ADD CONSTRAINT ck_loyalty_classification
--     CHECK (loyalty_classification IN ('Silver','Gold','Platinum','Diamond'));

INSERT INTO financial_customers (
    customer_id, first_name, last_name, email, phone_number,
    address, city, state, zip_code, country,
    sex, loyalty_classification, risk_weighting, income_band, dob
)
VALUES (
    20000, 'Jane', 'Doe', 'jane.doe@example.com', '555-867-5309',
    '1234 Oak Street', 'San Francisco', 'CA', '94105', 'US',
    'Female', 'Diamond', 5, 'High', '1978-06-15'
);


-- =============================================================
-- SECTION 3: Add Jane's active $500k mortgage at 7.50%
-- =============================================================
-- max loan_id = 20000 → using 20001.
-- loan_officer_id = 1001 (Sarah Chen, inserted in Section 1).
-- property_id = 1 (existing property record; adjust if needed).
-- date_created = 2019-03-15 → supports "7-year payment history" narrative.
-- ⚠️ GAP 2: 'active' is a new status value.
--
-- If a CHECK constraint exists, update it first. Example for PostgreSQL:
--   ALTER TABLE financial_loans DROP CONSTRAINT IF EXISTS ck_loan_status;
--   ALTER TABLE financial_loans ADD CONSTRAINT ck_loan_status
--     CHECK (status IN ('pending','approved','rejected','active'));
--
-- OR: change 'active' → 'approved' if you don't want schema changes.

INSERT INTO financial_loans (
    loan_id, customer_id, loan_amount, interest_rate,
    term, status, property_id, loan_officer_id, date_created
)
VALUES (
    20001, 20000, 500000.00, 7.50,
    30, 'active', 1, 1001, '2019-03-15'
);


-- =============================================================
-- SECTION 4: Add underwriting record — FICO 810, clean history
-- =============================================================
-- max underwriting_id = 2001 → using 2002.
-- financial_history text backs the "7-year no missed payments" claim in Q3.

INSERT INTO financial_underwriting (
    underwriting_id, loan_id, credit_score, employment_history, financial_history
)
VALUES (
    2002, 20001, 810, 'Stable', 'Excellent — no missed payments in 7 years'
);


-- =============================================================
-- SECTION 5: Add Jane's rate complaint (filed March 20, 2026)
-- =============================================================
-- max complaint_id = 4032 → using 4033.
-- complaint_date a few days before the March 24 branch visit (chronologically correct).
-- resolved = false → open complaint, signals active churn risk.
-- ⚠️ GAP 4: No sentiment column. Agent searches via complaint_text LIKE.
--    Keywords present for agent discovery: rate, competitor, switching, Diamond.
INSERT INTO customer_complaints (
    complaint_id, 
    customer_id, 
    complaint_text, 
    complaint_date, 
    channel, 
    resolved, 
    embedding
) 
values( 
    4033, 
    20000, 
    'My mortgage rate is way too high. I have been a loyal Diamond customer for six years with an excellent credit history and zero missed payments. Competitor B contacted me last week and offered 6.2% on a comparable 30-year fixed mortgage. My current rate of 7.50% is simply not competitive. I am seriously considering switching lenders unless we can match or beat that offer.', 
    '2026-03-20', 
    'call', 
    false, 
    embed_ai('My mortgage rate is way too high. I have been a loyal Diamond customer for six years with an excellent credit history and zero missed payments. Competitor B contacted me last week and offered 6.2% on a comparable 30-year fixed mortgage. My current rate of 7.50% is simply not competitive. I am seriously considering switching lenders unless we can match or beat that offer.'))

-- =============================================================
-- SECTION 6: Add branch visit transcript — March 24, 2026 with Sarah Chen
-- =============================================================
-- max transcript_id = 2214 → using 2215.
-- loan_officer_id = 1001 (Sarah Chen).
-- meeting_date = 2026-03-24 (matches demo script Q2 exactly).
-- meeting_type = 'branch_visit' (consistent with existing data values).
--
-- The key quote is present verbatim so the agent can surface it in Q2.
-- The text also contains: credit score, rate figures, competitor info, and
-- the defection risk signal for Q3 synthesis.


INSERT INTO officer_transcripts (
    transcript_id, customer_id, loan_officer_id,
    meeting_date, meeting_type, transcript_text, embedding
)
values(2215, 20000, 1001, '2026-03-24', 'branch_visit', 'Customer Jane Doe visited the branch on March 24, 2026 for a scheduled meeting with Relationship Manager Sarah Chen. Customer expressed strong frustration with her current mortgage rate of 7.50% on a $500,000 30-year fixed mortgage originated in March 2019. She stated that Competitor B contacted her last week and offered a rate of 6.2% on a comparable 30-year fixed mortgage. Customer has maintained a flawless payment record for over 7 years and confirmed her credit score is 810. She has been a Diamond loyalty tier customer for six years and expressed disappointment that her long-standing relationship has not resulted in a preferential rate. Key quote:"""I have been a Diamond customer for six years. I expect better. Competitor B called me last week with 6.2%. Match it or I am gone.""" RM Chen acknowledged the concern, confirmed she would escalate to the pricing team, and committed to responding with a formal rate offer within 24 hours. Customer defection risk assessed as high. Immediate follow-up action required.', embed_ai('Customer Jane Doe visited the branch on March 24, 2026 for a scheduled meeting with Relationship Manager Sarah Chen. Customer expressed strong frustration with her current mortgage rate of 7.50% on a $500,000 30-year fixed mortgage originated in March 2019. She stated that Competitor B contacted her last week and offered a rate of 6.2% on a comparable 30-year fixed mortgage. Customer has maintained a flawless payment record for over 7 years and confirmed her credit score is 810. She has been a Diamond loyalty tier customer for six years and expressed disappointment that her long-standing relationship has not resulted in a preferential rate. Key quote: """I have been a Diamond customer for six years. I expect better. Competitor B called me last week with 6.2%. Match it or I am gone.""" RM Chen acknowledged the concern, confirmed she would escalate to the pricing team, and committed to responding with a formal rate offer within 24 hours. Customer defection risk assessed as high. Immediate follow-up action required.')



-- =============================================================
-- SECTION 7: Add Mortgage rate at 6.00% (floor rate for counter-offer)
-- =============================================================
-- max rate_id = 5 → using 6.
-- ⚠️ GAP 3: financial_rates has no tier/product_type column.
--    Using loan_type='Mortgage' to distinguish from existing 'Fixed' rates.
--    The agent will find this via: SELECT * FROM financial_rates WHERE loan_type='Mortgage'
--    It will recommend 6.00% as the counter-offer — beating competitor's 6.2%.
--
-- The agent's rationale: FICO 810 + 7-year clean history → qualifies for floor rate.
-- The 0.2% gap below competitor (6.00% vs 6.2%) is the demo's "we beat them" moment.

INSERT INTO financial_rates (rate_id, loan_type, term, interest_rate)
VALUES (6, 'Mortgage', 30, 6.00);


-- =============================================================
-- VERIFICATION QUERIES
-- Run these via Denodo Query Tool or MCP after inserts to confirm
-- data is visible through the virtualization layer.
-- =============================================================

-- Verify all Jane Doe records exist and join correctly:
-- SELECT c.customer_id, c.first_name, c.last_name, c.loyalty_classification,
--        l.loan_id, l.loan_amount, l.interest_rate, l.status,
--        u.credit_score, u.financial_history
-- FROM financial_customers c
-- JOIN financial_loans l ON c.customer_id = l.customer_id
-- JOIN financial_underwriting u ON l.loan_id = u.loan_id
-- WHERE c.customer_id = 20000;

-- Verify complaint is findable via text search (as the agent will search):
-- SELECT complaint_id, complaint_text, complaint_date, resolved
-- FROM customer_complaints
-- WHERE customer_id = 20000;

-- Verify transcript is findable:
-- SELECT t.transcript_id, t.meeting_date, t.meeting_type, t.transcript_text,
--        o.first_name, o.last_name
-- FROM officer_transcripts t
-- JOIN financial_loanofficers o ON t.loan_officer_id = o.loan_officer_id
-- WHERE t.customer_id = 20000;

-- Verify mortgage rate is present:
-- SELECT * FROM financial_rates WHERE loan_type = 'Mortgage';


-- =============================================================
-- DEMO FLOW SUMMARY — what the agent will do with this data
-- =============================================================
-- Q1: Agent searches customer_complaints for rate/competitor keywords
--     + joins financial_customers to confirm Diamond loyalty tier
--     + joins financial_loans to show $500k at 7.50% active mortgage
--     → Surfaces Jane Doe as the at-risk VIP
--
-- Q2: Agent queries officer_transcripts for customer_id=20000, most recent date
--     + joins financial_loanofficers to resolve name → Sarah Chen
--     → Returns March 24 transcript with key quote
--
-- Q3: Agent queries financial_rates WHERE loan_type='Mortgage' → finds 6.00%
--     + queries financial_underwriting for credit_score → 810 qualifies
--     → Recommends 6.00% offer, framing competitor's 6.2% as the benchmark
-- =============================================================
