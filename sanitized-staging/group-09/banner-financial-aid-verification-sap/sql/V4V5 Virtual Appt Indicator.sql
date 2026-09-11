-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Literal student ID/SSN lists have been replaced with bind parameters where applicable.
-- Schema fields may remain internally where required for joins or comparison logic.
-- Do not commit query results or exports containing student records.

SELECT RORSTAT_TGRP_CODE TGRP, ROBUSDF_VALUE_198,

CASE
WHEN substr(SPRADDR_ZIP,1,5) <> RCRAPP1_ZIP
THEN 'ZIP CODE MISMATCH'
WHEN SPRADDR_STAT_CODE IS NULL AND RCRAPP1_STAT_CODE <> 'OH'
THEN 'Y'
WHEN SPRADDR_STAT_CODE IS NULL AND RCRAPP1_STAT_CODE = 'OH'
THEN 'MANUAL REVIEW'
WHEN SPRADDR_STAT_CODE <> 'OH' OR (SPRADDR_STAT_CODE = 'OH' AND NVL(SPRADDR_CNTY_CODE,'XX') not in ('STK', 'SUM','CYH','GGA','TMB','MAH','PRT'))
THEN 'Y'
WHEN SPRADDR_STAT_CODE = 'OH' AND NVL(SPRADDR_CNTY_CODE,'XX') IN ('STK', 'SUM','CYH','GGA','TMB','MAH','PRT')
THEN 'N'
ELSE 'MANUAL REVIEW'
END "Need Virtual Appt"

FROM RORSTAT

left join SPRADDR
on RORSTAT_PIDM = SPRADDR_PIDM
and SPRADDR_ATYP_CODE = 'PR'
and (SPRADDR_TO_DATE > sysdate
or SPRADDR_TO_DATE is null)
and SPRADDR_STATUS_IND is null

LEFT JOIN ROBUSDF
ON ROBUSDF_PIDM = RORSTAT_PIDM
AND ROBUSDF_AIDY_CODE = RORSTAT_AIDY_CODE

LEFT JOIN RCRAPP1
ON          RORSTAT_PIDM = RCRAPP1_PIDM
AND         RCRAPP1_AIDY_CODE = RORSTAT_AIDY_CODE
AND         RCRAPP1_INFC_CODE = 'EDE'
AND         RCRAPP1_CURR_REC_IND = 'Y'

where RORSTAT_AIDY_CODE = :aidy_code
and RORSTAT_TGRP_CODE in ('FAVERI','FAVERD','FAVER4')
