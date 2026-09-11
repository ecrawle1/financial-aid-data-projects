-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from public output.
-- Schema fields used internally for joins/comparisons are retained where required by query logic.
-- Do not commit query results or exports containing student records.

Select RRRAREQ_TREQ_CODE FAFSA, RRRAREQ_TRST_CODE FAFSA_STATUS,
RORSTAT_APPL_RCVD_DATE
from SPRIDEN
LEFT JOIN RORSTAT
ON SPRIDEN_PIDM = RORSTAT_PIDM
AND SPRIDEN_CHANGE_IND IS NULL
AND RORSTAT_AIDY_CODE = '2425'
LEFT Join RRRAREQ
ON RRRAREQ_PIDM = SPRIDEN_PIDM
and RRRAREQ_AIDY_CODE = '2425'
and RRRAREQ_TREQ_CODE = 'FAFSA'
LEFT JOIN RCRAPP1
ON SPRIDEN_PIDM = RCRAPP1_PIDM
AND SPRIDEN_CHANGE_IND IS NULL
where RCRAPP1_AIDY_CODE = '2425'
AND RCRAPP1_INFC_CODE = 'EDE'
AND RCRAPP1_CURR_REC_IND = 'Y'
and SPRIDEN_ID IN (:STUDENT_ID_1, :STUDENT_ID_2)
-- Supply authorized student IDs securely at runtime; do not hard-code them in source control.