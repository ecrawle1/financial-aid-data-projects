-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from public output.
-- Schema fields used internally for joins/comparisons are retained where required by query logic.
-- Do not commit query results or exports containing student records.

Select RHRCOMM_AIDY_CODE AIDY, RHRCOMM_CATEGORY_CODE CATCODE, RHRCOMM_ORIG_DATE CREATEDATE, RHRCOMM_ACTIVITY_DATE
from SPRIDEN

left join RHRCOMM
on SPRIDEN_PIDM = RHRCOMM_PIDM
and RHRCOMM_AIDY_CODE in ('2122', '2223')

where RHRCOMM_CATEGORY_CODE in ('BURADJ', 'COVCOD')
and SPRIDEN_CHANGE_IND IS NULL
and SPRIDEN_ID IN (:STUDENT_ID_1, :STUDENT_ID_2)
-- Supply authorized student IDs securely at runtime; do not hard-code them in source control.
Order by RHRCOMM_ACTIVITY_DATE