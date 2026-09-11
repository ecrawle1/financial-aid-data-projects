-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from public output.
-- Schema fields used internally for joins/comparisons are retained where required by query logic.
-- Do not commit query results or exports containing student records.

SELECT RPRATRM_FUND_CODE, RPRATRM_PERIOD, RPRATRM_OFFER_AMT, RPRATRM_PAID_AMT, RPRATRM_PAID_DATE
FROM RPRATRM
LEFT JOIN SPRIDEN ON RPRATRM_PIDM = SPRIDEN_PIDM AND SPRIDEN_CHANGE_IND IS NULL
WHERE RPRATRM_FUND_CODE = 'SSMTCS'
AND RPRATRM_PERIOD = :PERIOD
--AND RPRATRM_PAID_AMT >0
ORDER BY RPRATRM_FUND_CODE, RPRATRM_PERIOD