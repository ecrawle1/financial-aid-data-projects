-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Schema fields used internally for joins/comparisons are retained where required by the query logic.
-- Do not commit query results or exports containing student records.

Select RPRATRM_FUND_CODE, RPRATRM_OFFER_AMT, RPRATRM_PAID_AMT, 
SGRSCMT_TERM_CODE, SGRSCMT_ACTIVITY_DATE

from RPRATRM

left join SPRIDEN
on RPRATRM_PIDM = SPRIDEN_PIDM
and SPRIDEN_CHANGE_IND is null

left join SGRSCMT
on RPRATRM_PIDM = SGRSCMT_PIDM
and SGRSCMT_TERM_CODE= RPRATRM_PERIOD

where RPRATRM_PERIOD=:Term
and (RPRATRM_FUND_CODE like 'LF%'
or RPRATRM_FUND_CODE like 'GFNPEL')
and SGRSCMT_COMMENT_TEXT is not null
and RPRATRM_OFFER_AMT >0
