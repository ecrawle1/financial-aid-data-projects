-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Literal student ID/SSN lists have been replaced with bind parameters where applicable.
-- Schema fields may remain internally where required for joins or comparison logic.
-- Do not commit query results or exports containing student records.

select RRRAREQ_TREQ_CODE TREQ, RRRAREQ_TRST_CODE TRST, RRRAREQ_EST_DATE EST_DATE,
        RRRAREQ_STAT_DATE STATUS_DATE, RWBPLAP_ACTIVITY_DATE LOAD_DATE,
        RWBPLAP_BORROWER_CM_IND MTCH_IND,
        RWBPLAP_BATCH_DATE BATCH_DATE, RWBPLAP_LOAN_PERIOD_BEGIN, RWBPLAP_LOAN_PERIOD_END, ROBUSDF_VALUE_185
        
FROM RWBPLAP

LEFT JOIN RRRAREQ
ON          RWBPLAP_PIDM = RRRAREQ_PIDM
AND         RWBPLAP_AIDY_CODE = RRRAREQ_AIDY_CODE
AND         RRRAREQ_TREQ_CODE = 'SUPVL'

Left join ROBUSDF
on ROBUSDF_PIDM = RWBPLAP_PIDM
AND ROBUSDF_AIDY_CODE = RWBPLAP_AIDY_CODE

WHERE RWBPLAP_AIDY_CODE = :AIDY

ORDER BY RWBPLAP_BATCH_DATE DESC
