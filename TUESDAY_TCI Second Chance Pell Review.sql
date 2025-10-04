/* Formatted on 8/15/2025 3:58:30 PM (QP5 v5.422) */
SELECT SPBPERS_SSN                                                            STUDENT_SSN,
       SPRIDEN_ID                                                             ID,
       SPRIDEN_LAST_NAME                                                      LNAME,
       SPRIDEN_FIRST_NAME,
       RCRAPP1_AIDY_CODE                                                      AIDY_CODE,
       A.SGBSTDN_SITE_CODE,
       RCRAPP1_CURR_REC_IND                                                   FAFSA,
       RCRAPP2_PELL_PGI                                                       EFC,
       RORSTAT_APRD_CODE                                                      APRD,
       A.RBRAPBG_PBGP_CODE                                                    SMR_BUDG,
       B.RBRAPBG_PBGP_CODE                                                    FAL_BUDG,
       C.RBRAPBG_PBGP_CODE                                                    SPR_BUDG,
       RORSTAT_PGRP_CODE                                                      PCKG_GRP,
       RRRAREQ_TREQ_CODE                                                      NSLDS_REQ,
       RRRAREQ_TRST_CODE                                                      NSLDS_STAT_CODE,
       
       (SELECT SUM (SFRSTCR_CREDIT_HR)
          FROM SFRSTCR
         WHERE     SFRSTCR_PIDM = SPRIDEN_PIDM
               AND SFRSTCR_TERM_CODE = :SUM_TRM
               AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2'))                SMR_CR_HRS,
                                         
       (SELECT SUM (SFRSTCR_CREDIT_HR)
          FROM SFRSTCR
         WHERE     SFRSTCR_PIDM = SPRIDEN_PIDM
               AND SFRSTCR_TERM_CODE = :FAL_TRM
               AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2'))                FAL_CR_HRS,
       (SELECT SUM (SFRSTCR_CREDIT_HR)
          FROM SFRSTCR
         WHERE     SFRSTCR_PIDM = SPRIDEN_PIDM
               AND SFRSTCR_TERM_CODE = :SPR_TRM
               AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2'))                SPR_CR_HRS,
               
       D.RPRATRM_ACCEPT_AMT                                                   SMR_PELL_ACPT,
       D.RPRATRM_PAID_AMT                                                     SMR_PELL_PD,
       G.RPRATRM_ACCEPT_AMT                                                   SMR_SEOG_ACPT,
       G.RPRATRM_PAID_AMT                                                     SMR_SEOG_PD,
       E.RPRATRM_ACCEPT_AMT                                                   FAL_PELL_ACPT,
       E.RPRATRM_PAID_AMT                                                     FAL_PELL_PD,
       H.RPRATRM_ACCEPT_AMT                                                   FAL_SEOG_ACPT,
       H.RPRATRM_PAID_AMT                                                     FAL_SEOG_PD,
       F.RPRATRM_ACCEPT_AMT                                                   SPR_PELL_ACPT,
       F.RPRATRM_PAID_AMT                                                     SPR_PELL_PD,
       I.RPRATRM_ACCEPT_AMT                                                   SPR_SEOG_ACPT,
       I.RPRATRM_PAID_AMT                                                     SPR_SEOG_PD,
       
       (SELECT DISTINCT 'Y'
          FROM RRRAREQ
         WHERE     RRRAREQ_PIDM = SPRIDEN_PIDM
               AND RRRAREQ_AIDY_CODE = RCRAPP1_AIDY_CODE
               AND RRRAREQ_PCKG_IND = 'Y'
               AND RRRAREQ_SAT_IND = 'N')                                     PCKG_REQ_NOT_SAT,
               
       (SELECT RRRAREQ_TRST_CODE
          FROM RRRAREQ
         WHERE     RRRAREQ_PIDM = SPRIDEN_PIDM
               AND RRRAREQ_AIDY_CODE = RCRAPP1_AIDY_CODE
               AND RRRAREQ_TREQ_CODE = 'VERIF')                               VERIF_STATUS,
               
       (SELECT DISTINCT 'Y'
          FROM RORHOLD
         WHERE     RORHOLD_PIDM = SPRIDEN_PIDM
               AND RORHOLD_HOLD_CODE = 'PP'
               AND RORHOLD_AIDY_CODE = :AIDY
               AND TRUNC (RORHOLD_TO_DATE) > SYSDATE)                         PP_YEAR_HLD,
               
       (SELECT DISTINCT 'Y'
          FROM RORHOLD
         WHERE     RORHOLD_PIDM = SPRIDEN_PIDM
               AND RORHOLD_HOLD_CODE = 'PP'
               AND RORHOLD_PERIOD = :SUM_TRM
               AND TRUNC (RORHOLD_TO_DATE) > SYSDATE)                         PP_SMR_HLD,
               
       (SELECT DISTINCT 'Y'
          FROM RORHOLD
         WHERE     RORHOLD_PIDM = SPRIDEN_PIDM
               AND RORHOLD_HOLD_CODE = 'PP'
               AND RORHOLD_PERIOD = :FAL_TRM
               AND TRUNC (RORHOLD_TO_DATE) > SYSDATE)                         PP_FALL_HLD,
               
       (SELECT DISTINCT 'Y'
          FROM RORHOLD
         WHERE     RORHOLD_PIDM = SPRIDEN_PIDM
               AND RORHOLD_HOLD_CODE = 'PP'
               AND RORHOLD_PERIOD = :SPR_TRM
               AND TRUNC (RORHOLD_TO_DATE) > SYSDATE)                         PP_SPR_HLD,
               
       (SELECT SUM (TBRACCD_AMOUNT)
          FROM TBRACCD
         WHERE     TBRACCD_PIDM = SPRIDEN_PIDM
               AND TBRACCD_TERM_CODE = :SUM_TRM
               AND TBRACCD_DETAIL_CODE LIKE 'F%CS')                           SMR_CS_FEE,
               
       (SELECT SUM (TBRACCD_AMOUNT)
          FROM TBRACCD
         WHERE     TBRACCD_PIDM = SPRIDEN_PIDM
               AND TBRACCD_TERM_CODE = :FAL_TRM
               AND TBRACCD_DETAIL_CODE LIKE 'F%CS')                           FAL_CS_FEE,
               
       (SELECT SUM (TBRACCD_AMOUNT)
          FROM TBRACCD
         WHERE     TBRACCD_PIDM = SPRIDEN_PIDM
               AND TBRACCD_TERM_CODE = :SPR_TRM
               AND TBRACCD_DETAIL_CODE LIKE 'F%CS')                           SPR_CS_FEE,
               
       (SELECT SUM (TBRACCD_AMOUNT)
          FROM TBRACCD
         WHERE     TBRACCD_PIDM = SPRIDEN_PIDM
               AND TBRACCD_TERM_CODE = :SUM_TRM
               AND TBRACCD_DETAIL_CODE LIKE 'T%')                             SMR_TUI_FEES,
               
       (SELECT SUM (TBRACCD_AMOUNT)
          FROM TBRACCD
         WHERE     TBRACCD_PIDM = SPRIDEN_PIDM
               AND TBRACCD_TERM_CODE = :FAL_TRM
               AND TBRACCD_DETAIL_CODE LIKE 'T%')                             FAL_TUI_FEES,
               
       (SELECT SUM (TBRACCD_AMOUNT)
          FROM TBRACCD
         WHERE     TBRACCD_PIDM = SPRIDEN_PIDM
               AND TBRACCD_TERM_CODE = :SPR_TRM
               AND TBRACCD_DETAIL_CODE LIKE 'T%')                             SPR_TUI_FEES,
               
       (SELECT SUM (tbraccd_balance)     AS balance
          FROM tbraccd
         WHERE spriden_pidm = tbraccd_pidm AND spriden_change_ind IS NULL)    BALANCE
         
  FROM SGBSTDN  A
       
       LEFT JOIN SPRIDEN ON SPRIDEN_PIDM = A.SGBSTDN_PIDM
       
       LEFT JOIN SPBPERS ON SPRIDEN_PIDM = SPBPERS_PIDM
       
       LEFT JOIN RCRAPP1
           ON     SPRIDEN_PIDM = RCRAPP1_PIDM
              AND RCRAPP1_AIDY_CODE = :AIDY
              AND RCRAPP1_INFC_CODE = 'EDE'
              AND RCRAPP1_CURR_REC_IND = 'Y'
       
       LEFT JOIN RCRAPP2
           ON     SPRIDEN_PIDM = RCRAPP2_PIDM
              AND RCRAPP1_AIDY_CODE = RCRAPP2_AIDY_CODE
              AND RCRAPP1_INFC_CODE = RCRAPP2_INFC_CODE
              AND RCRAPP1_SEQ_NO = RCRAPP2_SEQ_NO
       
       LEFT JOIN RORSTAT
           ON SPRIDEN_PIDM = RORSTAT_PIDM AND RORSTAT_AIDY_CODE = :AIDY
       
       LEFT JOIN RBRAPBG A
           ON     A.RBRAPBG_PIDM = SPRIDEN_PIDM
              AND A.RBRAPBG_PERIOD = :SUM_TRM
              AND A.RBRAPBG_RUN_NAME = 'ACTUAL'
       
       LEFT JOIN RBRAPBG B
           ON     B.RBRAPBG_PIDM = SPRIDEN_PIDM
              AND B.RBRAPBG_PERIOD = :FAL_TRM
              AND B.RBRAPBG_RUN_NAME = 'ACTUAL'
       
       LEFT JOIN RBRAPBG C
           ON     C.RBRAPBG_PIDM = SPRIDEN_PIDM
              AND C.RBRAPBG_PERIOD = :SPR_TRM
              AND C.RBRAPBG_RUN_NAME = 'ACTUAL'
       
       LEFT JOIN RPRATRM D
           ON     D.RPRATRM_PIDM = SPRIDEN_PIDM
              AND D.RPRATRM_PERIOD = :SUM_TRM
              AND D.RPRATRM_FUND_CODE = 'GFNPEL'
       
       LEFT JOIN RPRATRM G
           ON     G.RPRATRM_PIDM = SPRIDEN_PIDM
              AND G.RPRATRM_PERIOD = :SUM_TRM
              AND G.RPRATRM_FUND_CODE = 'GFNSEO'
       
       LEFT JOIN RPRATRM E
           ON     E.RPRATRM_PIDM = SPRIDEN_PIDM
              AND E.RPRATRM_PERIOD = :FAL_TRM
              AND E.RPRATRM_FUND_CODE = 'GFNPEL'
       
       LEFT JOIN RPRATRM H
           ON     H.RPRATRM_PIDM = SPRIDEN_PIDM
              AND H.RPRATRM_PERIOD = :FAL_TRM
              AND H.RPRATRM_FUND_CODE = 'GFNSEO'
       
       LEFT JOIN RPRATRM F
           ON     F.RPRATRM_PIDM = SPRIDEN_PIDM
              AND F.RPRATRM_PERIOD = :SPR_TRM
              AND F.RPRATRM_FUND_CODE = 'GFNPEL'
       
       LEFT JOIN RPRATRM I
           ON     I.RPRATRM_PIDM = SPRIDEN_PIDM
              AND I.RPRATRM_PERIOD = :SPR_TRM
              AND I.RPRATRM_FUND_CODE = 'GFNSEO'
              
       LEFT JOIN RRRAREQ J
           ON     SPRIDEN_PIDM = J.RRRAREQ_PIDM
              AND J.RRRAREQ_TREQ_CODE IN ('NSLDSA','NSLDSB','NSLDSD','NSLDSR','NSLDS','NSLDSG','NSLDSN','NSLDSP')
              AND J.RRRAREQ_AIDY_CODE = :AIDY
              
 WHERE     A.SGBSTDN_TERM_CODE_EFF =
           (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
              FROM SGBSTDN Z
             WHERE     Z.SGBSTDN_PIDM = A.SGBSTDN_PIDM
                   AND Z.SGBSTDN_TERM_CODE_EFF <= :SPR_TRM)
       AND A.SGBSTDN_SITE_CODE = 'TCI'
       AND SPRIDEN_CHANGE_IND IS NULL
       
       Order by 3