-- SANITIZED PUBLIC VERSION
-- Direct student/borrower identifiers and hard-coded student data have been removed from public output.
-- Literal student ID/SSN lists have been replaced with bind parameters where applicable.
-- Schema fields may remain internally where required for joins, filtering, or comparison logic.
-- Do not commit query results or exports containing student records.

--RUN SMR/FALL/SPR THEN JUST FALL WEEKLY - TUESDAYS

  SELECT NULL AS STUDENT_ID,
         NULL AS STUDENT_FIRST_NAME,
         NULL AS STUDENT_LAST_NAME,
         RORSTAT_APRD_CODE                             APRD,
         SGBSTDN_TERM_CODE_EFF,
         SGBSTDN_STST_CODE,
         SGBSTDN_RATE_CODE                             COHORT,
         SGBSTDN_RESD_CODE                             RES,
         SGBSTDN_PROGRAM_1                             PROGRAM_1,
         SGBSTDN_CAMP_CODE                             CAMPUS_1,
         SGBSTDN_LEVL_CODE                             LEVL_1, 
         SGBSTDN_RATE_CODE,
         -- SGBSTDN_PROGRAM_2 PROGRAM_2, SGBSTDN_LEVL_CODE_2 LEVL_2, SGBSTDN_CAMP_CODE_2 CAMPUS_2,
         RBRAPBG_PERIOD                                BUDGET_TERM,
         RBRAPBG_PBGP_CODE                             BUDGET_GRP,
         TO_CHAR(T.RBRAPBC_AMT,'$999,999,990.00') AS   TF_AMT,
         T.RBRAPBC_SYS_IND                             TF_SYS_IND,
         TO_CHAR(S.RBRAPBC_AMT,'$999,999,990.00') AS   SURC_AMT,
         S.RBRAPBC_SYS_IND                             SURC_SYS_IND,

         (SELECT SUM (SFRSTCR_CREDIT_HR)
            FROM SFRSTCR
           WHERE     SFRSTCR_PIDM = RORSTAT_PIDM
                 AND SFRSTCR_RSTS_CODE IN ('RR','RE','R2','RW')
                 AND SFRSTCR_TERM_CODE = :TERM)        TERM_REGISTERED_HOURS,

        ROKMISC_RULES.F_CALC_RULE_HRS_NO_ROTSREG(:AIDY, RORSTAT_PIDM, :TERM, 'FEDAID') AS TERM_FEDAID_HOURS,                 
                 
         TO_CHAR(RNVAND0_BUDGET_AMOUNT,'$999,999,990.00') AS YEAR_BUDGET,
         TO_CHAR(RNVAND0_UNMET_NEED, '$999,999,990.00') AS YR_UNMET_NEED,
         
        TO_CHAR(
        (SELECT SUM (RBRAPBC_AMT)
            FROM RBRAPBC
           WHERE     RBRAPBC_PIDM = RORSTAT_PIDM
                 AND (   RBRAPBC_PERIOD = :TERM
                      OR RBRAPBC_PERIOD LIKE
                             (CASE
                                  WHEN :TERM LIKE '%60' THEN '%55%'
                                  WHEN :TERM LIKE '%80' THEN '%75%'
                                  WHEN :TERM LIKE '%10' THEN '%05%'
                              END))
                 AND RBRAPBC_RUN_NAME = 'ACTUAL'
                 AND RBRAPBC_PBTP_CODE = 'COA'), 
            '$999,999,990.00') AS TERM_BUDGET,
                 
         TO_CHAR(
            (SELECT SUM (RPRATRM_OFFER_AMT)
            FROM RPRATRM
           WHERE     RPRATRM_PIDM = RORSTAT_PIDM
                 AND RPRATRM_OFFER_AMT > 0
                 AND RPRATRM_PERIOD = :TERM), 
            '$999,999,990.00') AS TERM_TOTAL_AID_OFFERED,

         TO_CHAR(
         (SELECT SUM (TBRACCD_AMOUNT)
            FROM TBRACCD
           WHERE     TBRACCD_PIDM = RORSTAT_PIDM
                 AND TBRACCD_TERM_CODE = :TERM
                 AND TBRACCD_DETAIL_CODE LIKE 'T%'), 
            '$999,999,990.00') AS TUITION_CHRGES

    FROM RORSTAT
         LEFT JOIN SPRIDEN
             ON SPRIDEN_PIDM = RORSTAT_PIDM AND SPRIDEN_CHANGE_IND IS NULL
             
         LEFT JOIN SGBSTDN ON SGBSTDN_PIDM = RORSTAT_PIDM

         LEFT JOIN RNVAND0
             ON     RNVAND0_AIDY_CODE = RORSTAT_AIDY_CODE
                AND RNVAND0_PIDM = RORSTAT_PIDM

         LEFT JOIN RBRAPBG
             ON     RBRAPBG_PIDM = RORSTAT_PIDM
                AND RBRAPBG_AIDY_CODE = RORSTAT_AIDY_CODE
                AND RBRAPBG_RUN_NAME = 'ACTUAL'
                AND (   RBRAPBG_PERIOD = :TERM
                     OR RBRAPBG_PERIOD LIKE
                            (CASE
                                 WHEN :TERM LIKE '%60' THEN '%55%'
                                 WHEN :TERM LIKE '%80' THEN '%75%'
                                 WHEN :TERM LIKE '%10' THEN '%05%'
                             END))

         LEFT JOIN RBRAPBC T
             ON     T.RBRAPBC_AIDY_CODE = RORSTAT_AIDY_CODE
                AND T.RBRAPBC_PIDM = RORSTAT_PIDM
                AND T.RBRAPBC_RUN_NAME = 'ACTUAL'
                AND T.RBRAPBC_PBTP_CODE = 'COA'
                AND (   T.RBRAPBC_PERIOD = :TERM
                     OR T.RBRAPBC_PERIOD LIKE
                            (CASE
                                 WHEN :TERM LIKE '%60' THEN '%55%'
                                 WHEN :TERM LIKE '%80' THEN '%75%'
                                 WHEN :TERM LIKE '%10' THEN '%05%'
                             END))
                AND T.RBRAPBC_PBCP_CODE = 'T+F'

         LEFT JOIN RBRAPBC S
             ON     S.RBRAPBC_AIDY_CODE = RORSTAT_AIDY_CODE
                AND S.RBRAPBC_PIDM = RORSTAT_PIDM
                AND S.RBRAPBC_RUN_NAME = 'ACTUAL'
                AND S.RBRAPBC_PBTP_CODE = 'COA'
                AND (   S.RBRAPBC_PERIOD = :TERM
                     OR S.RBRAPBC_PERIOD LIKE
                            (CASE
                                 WHEN :TERM LIKE '%60' THEN '%55%'
                                 WHEN :TERM LIKE '%80' THEN '%75%'
                                 WHEN :TERM LIKE '%10' THEN '%05%'
                             END))
                AND S.RBRAPBC_PBCP_CODE = 'SURC'

   WHERE     RORSTAT_AIDY_CODE = :AIDY
         AND SGBSTDN_TERM_CODE_EFF =
             (SELECT MAX (Z.SGBSTDN_TERM_CODE_EFF)
                FROM SGBSTDN Z
               WHERE     Z.SGBSTDN_PIDM = RORSTAT_PIDM
                     AND Z.SGBSTDN_TERM_CODE_EFF <= :TERM)
         AND SGBSTDN_RATE_CODE = 'DDRC'
         AND NVL (RBRAPBG_PBGP_CODE, 'DEFALT') <> 'DEFALT'
ORDER BY SGBSTDN_STST_CODE, SGBSTDN_RATE_CODE DESC