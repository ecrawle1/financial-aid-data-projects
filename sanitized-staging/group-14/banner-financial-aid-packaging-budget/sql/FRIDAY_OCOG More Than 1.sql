/*
FERPA-SAFE PUBLIC VERSION
Direct student/borrower identifiers have been removed or masked from the final result set where practical.
Hard-coded student IDs, SSNs, personal email values, individualized free-text output, and staff user identifiers were removed or parameterized where applicable.
Schema fields may remain internally where required for joins, filtering, calculation, or comparison logic.
This repository contains SQL code only. Do not commit query output or student-level data.
*/

SELECT *
  FROM (  SELECT NULL AS SPRIDEN_ID, NULL AS SPRIDEN_FIRST_NAME, NULL AS SPRIDEN_LAST_NAME, COUNT(RPRATRM_FUND_CODE) FUND_COUNT
            FROM RPRATRM, SPRIDEN
           WHERE     RPRATRM_PIDM = SPRIDEN_PIDM
                 AND SPRIDEN_CHANGE_IND IS NULL
                 AND RPRATRM_OFFER_AMT > 0
                 AND RPRATRM_PERIOD = :TERM
                 AND RPRATRM_FUND_CODE LIKE 'GSNO%'
        GROUP BY SPRIDEN_ID, SPRIDEN_FIRST_NAME, SPRIDEN_LAST_NAME)
 WHERE FUND_COUNT > 1