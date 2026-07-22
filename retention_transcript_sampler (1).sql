-- Retention call transcript sampler: pulls randomized retention calls for a given month and set of zip codes
-- Co-authored with CoCo
--
-- Extracts a random sample of retention call transcripts joined to subscriber
-- and site data. Used to build labeled datasets for GenAI feature extraction.
--
-- Prerequisites:
--   - A redacted transcripts table with columns: DAILY_TIME_KEY, CUSTOMER_KEY,
--     TRANSCRIPT_INTERACTION_ID, CALL_START_TIME_UTC, CALL_END_TIME_UTC,
--     SITE_ID, BUSINESS_APP, CONVERSATION
--   - A monthly customer fact view with site and house keys
--   - A site dimension view and house dimension view
--   - A subscriber performance metrics table
--
-- Configuration:
--   - Update the zip code list in the WHERE clause for your target geography
--   - Adjust the date range filter as needed
--   - Change the sample size (rand_rank <= N) for more or fewer records

--------------------------------------------------------------------------------
-- Create sample extract of retention call transcripts
--------------------------------------------------------------------------------
DROP TABLE IF EXISTS <YOUR_DB>.<YOUR_SCHEMA>.RETENTION_TRANSCRIPT_EXTRACT;

CREATE TABLE <YOUR_DB>.<YOUR_SCHEMA>.RETENTION_TRANSCRIPT_EXTRACT AS
WITH prep AS (
    -- Pull all retention calls in the selected timeline and zip codes.
    -- Excludes non-customer calls (CUSTOMER_KEY = -2) and off-network sites.
    -- rand_rank randomly orders records for sampling.
    SELECT
        l.DAILY_TIME_KEY,
        l.CUSTOMER_KEY,
        s.SITE_DESC,
        h.SCRB_ADDRESS_ZIP5,

        CASE
            WHEN CURR_TE_CODE_STRING LIKE '%CR01ACQCORE%'
              OR CURR_TE_CODE_STRING LIKE '%RCR01RETCORE%'  THEN 'CR1'
            WHEN CURR_TE_CODE_STRING LIKE '%CR02ACQCORE%'
              OR CURR_TE_CODE_STRING LIKE '%RCR02RETCORE%'  THEN 'CR2'
            WHEN CURR_TE_CODE_STRING LIKE '%RCR02RETNODUB%' THEN 'CR2-LITE'
            WHEN CURR_TE_CODE_STRING LIKE '%CR03ACQCORE%'
              OR CURR_TE_CODE_STRING LIKE '%RCR03RETCORE%'  THEN 'CR3'
            WHEN CURR_TE_CODE_STRING LIKE '%CR04ACQCORE%'
              OR CURR_TE_CODE_STRING LIKE '%RCR04RETCORE%'  THEN 'CR4'
            WHEN CURR_TE_CODE_STRING LIKE '%RCR04RETNODUB%' THEN 'CR4-LITE'
            WHEN CURR_TE_CODE_STRING LIKE '%RCR06RETCORE%'
              OR CURR_TE_CODE_STRING LIKE '%CR06ACQCORE%'   THEN 'CR6'
            ELSE 'NO CR GROUP'
        END AS top_cr_group,

        l.TRANSCRIPT_INTERACTION_ID AS interaction_id,
        l.CALL_START_TIME_UTC,
        l.CALL_END_TIME_UTC,
        DATEDIFF(MINUTE, l.CALL_START_TIME_UTC, l.CALL_END_TIME_UTC) AS call_duration_min,
        l.SITE_ID,
        l.BUSINESS_APP,
        l.CONVERSATION,
        ROW_NUMBER() OVER (ORDER BY RANDOM()) AS rand_rank

    FROM <YOUR_DB>.<YOUR_SCHEMA>.REDACTED_TRANSCRIPTS_DAILY AS l
    LEFT JOIN <YOUR_DB>.<YOUR_SCHEMA>.CUSTOMER_MONTHLY_FACT AS c
        ON l.CUSTOMER_KEY = c.CUSTOMER_KEY
        AND LAST_DAY(l.TIME_KEY) = c.TIME_KEY
    LEFT JOIN <YOUR_DB>.<YOUR_SCHEMA>.SITE_DIM AS s
        ON s.SITE_KEY = c.SITE_KEY
    JOIN <YOUR_DB>.<YOUR_SCHEMA>.HOUSE_DIM AS h
        ON c.HOUSE_KEY = h.HOUSE_KEY
    LEFT JOIN <YOUR_DB>.<YOUR_SCHEMA>.SUBS_CAMPAIGN_PERFORMANCE_METRICS AS bios
        ON bios.CUSTOMER_KEY = l.CUSTOMER_KEY
        AND bios.DAILY_TIME_KEY = l.DAILY_TIME_KEY

    WHERE l.DAILY_TIME_KEY >= DATE_TRUNC('MONTH', ADD_MONTHS(CURRENT_DATE, -1))
      AND l.DAILY_TIME_KEY <= LAST_DAY(ADD_MONTHS(CURRENT_DATE, -1))
      AND l.BUSINESS_APP IN ('Retention')
      AND h.SCRB_ADDRESS_ZIP5 IN (
          -- Replace with your target zip codes
          '00001', '00002', '00003', '00004', '00005'
      )
      AND l.CUSTOMER_KEY != -2
      AND s.SITE_DESC != 'Off Network'
    ORDER BY l.CALL_START_TIME_UTC ASC
)
-- Select a random sample of N records
SELECT *
FROM prep
WHERE rand_rank <= 200;
