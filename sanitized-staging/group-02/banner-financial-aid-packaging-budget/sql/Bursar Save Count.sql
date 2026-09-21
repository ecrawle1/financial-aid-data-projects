-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Schema fields used internally for joins/comparisons are retained where required by the query logic.
-- Do not commit query results or exports containing student records.

select COUNT(TZRSTSF_PIDM), TZRSTSF_STATUS_CODE, TZRSTSF_TERM
FROM TZRSTSF 
LEFT JOIN SPRIDEN ON TZRSTSF_PIDM = SPRIDEN_PIDM
WHERE SPRIDEN_CHANGE_IND IS NULL
AND TZRSTSF_STATUS_CODE = 'F'
AND TZRSTSF_TERM = :term
AND TZRSTSF_ACTIVITY_DATE = (SELECT MAX(TZRSTSF_ACTIVITY_DATE) FROM TZRSTSF Z WHERE Z.TZRSTSF_PIDM = SPRIDEN_PIDM AND Z.TZRSTSF_TERM = :term)
GROUP BY TZRSTSF_STATUS_CODE, TZRSTSF_TERM