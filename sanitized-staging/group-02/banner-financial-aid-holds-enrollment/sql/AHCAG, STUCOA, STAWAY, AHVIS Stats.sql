-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Schema fields used internally for joins/comparisons are retained where required by the query logic.
-- Do not commit query results or exports containing student records.

SELECT RRRAREQ_AIDY_CODE AIDY, RRRAREQ_TREQ_CODE TREQ, RRRAREQ_TRST_CODE STATUS, RRRAREQ_EST_DATE ESTABLISHED_DATE, RRRAREQ_STAT_DATE STATUS_DATE

FROM RRRAREQ, SPRIDEN

WHERE RRRAREQ_AIDY_CODE = :AIDY
AND RRRAREQ_TREQ_CODE IN ('AHCAG','STUCOA','STAWAY','AHVIS')
AND SPRIDEN_PIDM = RRRAREQ_PIDM
AND SPRIDEN_CHANGE_IND IS NULL

ORDER BY RRRAREQ_TREQ_CODE, RRRAREQ_TRST_CODE
