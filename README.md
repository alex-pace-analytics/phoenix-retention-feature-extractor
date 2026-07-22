# Phoenix Retention Feature Extractor

Snowflake SQL script that classifies GenAI-extracted call reasons and agent offer outcomes, then measures their impact on subscriber disconnect rates and ARPC (Average Revenue Per Customer).

## What It Does

1. Categorizes call reasons into groups: `WantToDisconnect`, `Billing/Charge`, `Dissatisfied with Service`, `Other`
2. Classifies whether an agent made a retention offer (`Yes` / `No` / `Other`)
3. Classifies the final call outcome: `WantToLeave`, `TookOffer`, `NothingChanged`
4. Joins to subscriber performance metrics for 30/60/90-day disconnect flags and MRC (Monthly Recurring Charge) data
5. Aggregates results by call reason, offer status, and outcome

## Prerequisites

- **Snowflake account** with access to:
  - A GenAI response table containing columns: `CALLREASON`, `OFFERFROMAGENT`, `FINALOUTPUT`, `CUSTOMER_KEY`, `DAILY_TIME_KEY`
  - A subscriber performance metrics table containing: `DISCONNECT_FLAG_30_DAYS`, `DISCONNECT_FLAG_60_DAYS`, `DISCONNECT_FLAG_90_DAYS`, `TOTAL_NET_MRC_CURR`, `TOTAL_NET_MRC_30_DAYS`

## Setup

1. Replace all `<YOUR_DB>.<YOUR_SCHEMA>` placeholders in `phoenix_retention_feature_extractor.sql` with your actual database and schema names.

2. Replace table names if yours differ:
   - `GENAI_RETENTION_RESPONSES` — your GenAI call analysis output table
   - `SUBS_CAMPAIGN_PERFORMANCE_METRICS` — your subscriber performance metrics table

3. Run in any Snowflake SQL client (Snowsight, SnowSQL, etc.).

## Example Usage

```sql
-- After replacing placeholders:
SELECT *
FROM ANALYTICS.RETENTION.GENAI_RETENTION_RESPONSES;
```

## Output

The main query returns one row per combination of:

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
