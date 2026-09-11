-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Literal student ID/SSN lists have been replaced with bind parameters where applicable.
-- Schema fields may remain internally where required for joins or comparison logic.
-- Do not commit query results or exports containing student records.

select RRRAREQ_TREQ_CODE, RORSTAT_TGRP_CODE, RRRAREQ_TRST_CODE, RRRAREQ_STAT_DATE, RORSTAT_TGRP_CODE_LOCK_IND

from RRRAREQ   

left join rorstat
on RRRAREQ_PIDM = RORSTAT_PIDM
and RORSTAT_AIDY_CODE = RRRAREQ_AIDY_CODE

where RRRAREQ_AIDY_CODE = :Aid_Year
and RRRAREQ_TREQ_CODE ='VERIF'
and RRRAREQ_TRST_CODE in ('P','C','I','F','M')
and RORSTAT_TGRP_CODE <> 'FAFREJ'
and (RORSTAT_TGRP_CODE_LOCK_IND='N'
or RORSTAT_TGRP_CODE_LOCK_IND is null)
