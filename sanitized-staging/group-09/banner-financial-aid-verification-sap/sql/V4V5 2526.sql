-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Literal student ID/SSN lists have been replaced with bind parameters where applicable.
-- Schema fields may remain internally where required for joins or comparison logic.
-- Do not commit query results or exports containing student records.

Select B.RRRAREQ_TRST_CODE SEDPUX_STATUS, B.RRRAREQ_STAT_DATE SEDPUX_DATE, C.RRRAREQ_TRST_CODE STUID_STATUS, C.RRRAREQ_STAT_DATE STUID_DATE, 
 D.RRRAREQ_TRST_CODE VERIF_STATUS, D.RRRAREQ_STAT_DATE VERIF_DATE,ROBUSDF_VALUE_198, RORSTAT_TGRP_CODE TGRP,
 
        (SELECT DISTINCT 'Y'
        FROM GURMAIL
        WHERE RORSTAT_PIDM = GURMAIL_PIDM
        AND GURMAIL_LETR_CODE = 'FA_VERIF_2526') VERIF_2526_EMAIL

from RORSTAT

left join RRRAREQ B
on RORSTAT_PIDM = B.RRRAREQ_PIDM 
and RORSTAT_AIDY_CODE = B.RRRAREQ_AIDY_CODE
and B.RRRAREQ_TREQ_CODE = 'SEDPUX'

left join RRRAREQ C
on RORSTAT_PIDM = C.RRRAREQ_PIDM 
and RORSTAT_AIDY_CODE = C.RRRAREQ_AIDY_CODE
and C.RRRAREQ_TREQ_CODE = 'STUID'

left join RRRAREQ D
on RORSTAT_PIDM = D.RRRAREQ_PIDM 
and RORSTAT_AIDY_CODE = D.RRRAREQ_AIDY_CODE
and D.RRRAREQ_TREQ_CODE = 'VERIF'

left join ROBUSDF
on RORSTAT_PIDM = ROBUSDF_PIDM
and RORSTAT_AIDY_CODE = ROBUSDF_AIDY_CODE

where RORSTAT_AIDY_CODE = :aidy_code
and RORSTAT_TGRP_CODE in ('FAVERI','FAVERD','FAVER4')
