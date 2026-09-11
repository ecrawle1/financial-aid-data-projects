-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from public output.
-- Schema fields used internally for joins/comparisons are retained where required by query logic.
-- Do not commit query results or exports containing student records.

select RLRDLDD_PERIOD, RLRDLDD_FEED_IND, RLRDLDD_FEED_DATE, RLRDLDD_DISB_STATUS
from RLRDLOR
left join spriden
on rlrdlor_pidm = spriden_pidm
and spriden_change_ind is null
left join RLRDLDD
on rlrdlor_pidm = rlrdldd_pidm
and RLRDLOR_LOAN_NO = RLRDLDD_LOAN_NO
and RLRDLOR_AIDY_CODE = RLRDLDD_AIDY_CODE
where RLRDLOR_AIDY_CODE ='2021'