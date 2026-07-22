# Phoenix Retention Analytics

Snowflake SQL toolkit for analyzing retention call transcripts using GenAI feature extraction and measuring their impact on subscriber churn and revenue.

## Scripts

### 1. `retention_transcript_sampler.sql`

Builds a randomized sample of retention call transcripts for labeling and GenAI processing.

**What it does:**
- Pulls retention calls from the prior month for a configurable set of zip codes
- Joins transcripts to subscriber, site, and house dimension data
- Classifies each customer into a CR (Customer Retention) tier group (CR1–CR6)
- Randomly samples N records (default: 200) for downstream analysis

**Output columns:**

| Column | Description |
|--------|-------------|
| `DAILY_TIME_KEY` | Date of the call |
| `CUSTOMER_KEY` | Customer identifier |
| `SITE_DESC` | Call center site name |
| `SCRB_ADDRESS_ZIP5` | Customer zip code |
| `top_cr_group` | CR tier classification (CR1–CR6 or NO CR GROUP) |
| `interaction_id` | Unique transcript interaction ID |
| `CALL_START_TIME_UTC` | Call start timestamp |
| `CALL_END_TIME_UTC` | Call end timestamp |
| `call_duration_min` | Call duration in minutes |
| `CONVERSATION` | Redacted transcript text |

---

### 2. `phoenix_retention_feature_extractor.sql`

Classifies GenAI-extracted call attributes and measures their impact on disconnect rates and ARPC.

**What it does:**
1. Categorizes call reasons: `WantToDisconnect`, `Billing/Charge`, `Dissatisfied with Service`, `Other`
2. Classifies agent offer status: `Yes`, `No`, `Other`
3. Classifies final call outcome: `WantToLeave`, `TookOffer`, `NothingChanged`
4. Joins to subscriber performance metrics for 30/60/90-day disconnect flags and MRC data
5. Aggregates results by call reason, offer status, and outcome

**Output columns:**

| Column | Description |
|--------|-------------|
| `call_reason_group` | Categorized call reason |
| `offer_group` | Whether an offer was made |
| `final_output_group` | Call outcome classification |
| `row_count` | Number of interactions |
| `disconnect_flag_30_days` | Disconnects within 30 days |
| `disconnect_flag_60_days` | Disconnects within 60 days |
| `disconnect_flag_90_days` | Disconnects within 90 days |
| `total_net_mrc_curr` | Current total net MRC |
| `total_net_mrc_30_days` | MRC at 30 days |
| `arrpc_change_30d` | ARPC change over 30 days |

## Workflow

```
┌─────────────────────────────┐     ┌──────────────────────────────────┐
│ retention_transcript_sampler │ ──▶ │ GenAI processing (e.g. Cortex)   │
│ (random sample of calls)    │     │ (extracts call reason, offer,    │
└─────────────────────────────┘     │  outcome from transcripts)       │
                                    └──────────────┬───────────────────┘
                                                   ▼
                                    ┌──────────────────────────────────┐
                                    │ phoenix_retention_feature_extractor│
                                    │ (classify + measure impact)       │
                                    └──────────────────────────────────┘
```

## Setup

1. Replace all `<YOUR_DB>.<YOUR_SCHEMA>` placeholders with your actual database and schema names.

2. Replace generic table names with yours:
   - `REDACTED_TRANSCRIPTS_DAILY` — call transcript table
   - `CUSTOMER_MONTHLY_FACT` — monthly customer fact view
   - `SITE_DIM` — site dimension
   - `HOUSE_DIM` — house/address dimension
   - `SUBS_CAMPAIGN_PERFORMANCE_METRICS` — subscriber performance metrics
   - `GENAI_RETENTION_RESPONSES` — GenAI extraction output

3. In `retention_transcript_sampler.sql`, update:
   - The zip code list in the `WHERE` clause
   - The sample size (`rand_rank <= 200`)
   - The date range if you want something other than last month

4. Run in any Snowflake SQL client (Snowsight, SnowSQL, etc.).

## Requirements

- Snowflake account with SELECT access to the source tables
- A warehouse with sufficient compute for the transcript join
