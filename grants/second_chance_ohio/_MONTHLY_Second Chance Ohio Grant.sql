SELECT id,
       lname,
       fname,
       FAFSA,
       fund,
       ofrd,
       acpt_amt,
       pd_amt,
       NEED,
       COA,
       rpratrm_period,
       curr_program,
       curr_majr,
       prior_term,
       
       (SELECT SGBSTDN_RESD_CODE
          FROM SGBSTDN
         WHERE     SGBSTDN_PIDM = RPRATRM_PIDM
               AND SGBSTDN_TERM_CODE_EFF =
                   (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                      FROM SGBSTDN Z
                     WHERE     Z.SGBSTDN_PIDM = RPRATRM_PIDM
                           AND Z.SGBSTDN_TERM_CODE_EFF <= PRIOR_TERM)) RESIDENCY,
       (SELECT SGBSTDN_PROGRAM_1
          FROM SGBSTDN
         WHERE     SGBSTDN_PIDM = RPRATRM_PIDM
               AND SGBSTDN_TERM_CODE_EFF =
                   (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                      FROM SGBSTDN Z
                     WHERE     Z.SGBSTDN_PIDM = RPRATRM_PIDM
                           AND Z.SGBSTDN_TERM_CODE_EFF <= PRIOR_TERM)) PRIOR_PROGRAM,
       (SELECT SGBSTDN_MAJR_CODE_1
          FROM SGBSTDN
         WHERE     SGBSTDN_PIDM = RPRATRM_PIDM
               AND SGBSTDN_TERM_CODE_EFF =
                   (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                      FROM SGBSTDN Z
                     WHERE     Z.SGBSTDN_PIDM = RPRATRM_PIDM
                           AND Z.SGBSTDN_TERM_CODE_EFF <= PRIOR_TERM)) PRIOR_MAJR,
                           
       (SELECT SUM (SFRSTCR_CREDIT_HR)
          FROM SFRSTCR
         WHERE     SFRSTCR_PIDM = RPRATRM_PIDM
               AND SFRSTCR_TERM_CODE = :PRIOR_SMR
               AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) HOURS_SUM_PRIOR,
               
       (SELECT SUM (SFRSTCR_CREDIT_HR)
          FROM SFRSTCR
         WHERE     SFRSTCR_PIDM = RPRATRM_PIDM
               AND SFRSTCR_TERM_CODE = :PRIOR_FAL
               AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) HOURS_FALL_PRIOR,
               
       (SELECT SUM (SFRSTCR_CREDIT_HR)
          FROM SFRSTCR
         WHERE     SFRSTCR_PIDM = RPRATRM_PIDM
               AND SFRSTCR_TERM_CODE = :PRIOR_SPR
               AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) HOURS_SPRG_PRIOR,
               
       (SELECT DISTINCT 'Y'
          FROM SHRDGMR
         WHERE     SHRDGMR_PIDM = RPRATRM_PIDM
               AND SHRDGMR_DEGS_CODE = 'AW'
               AND SHRDGMR_TERM_CODE_GRAD > PRIOR_TERM) GRAD_RECORD,
               
       PD_STATE_AID,
       MIN_PRTR_ACT_DT
       
  FROM (SELECT RPRATRM_PIDM,
               SPRIDEN_ID                      ID,
               SPRIDEN_LAST_NAME               LNAME,
               SPRIDEN_FIRST_NAME              FNAME,
               RORSTAT_APPL_RCVD_DATE          FAFSA,
               RNVAND0_UNMET_NEED              NEED,
               RNVAND0_BUDGET_AMOUNT           COA,
               RPRATRM_FUND_CODE               fund,
               RPRATRM_OFFER_AMT               OFRD,
               RPRATRM_ACCEPT_AMT              ACPT_AMT,
               RPRATRM_PAID_AMT                PD_AMT,
               RPRATRM_PERIOD,
               
               (SELECT SGBSTDN_PROGRAM_1
                  FROM SGBSTDN
                 WHERE     SGBSTDN_PIDM = RPRATRM_PIDM
                       AND SGBSTDN_TERM_CODE_EFF =
                           (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                              FROM SGBSTDN Z
                             WHERE     Z.SGBSTDN_PIDM = RPRATRM_PIDM
                                   AND Z.SGBSTDN_TERM_CODE_EFF <= RPRATRM_PERIOD)) CURR_PROGRAM,
                                   
               (SELECT SGBSTDN_MAJR_CODE_1
                  FROM SGBSTDN
                 WHERE     SGBSTDN_PIDM = RPRATRM_PIDM
                       AND SGBSTDN_TERM_CODE_EFF =
                           (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                              FROM SGBSTDN Z
                             WHERE     Z.SGBSTDN_PIDM = RPRATRM_PIDM
                                   AND Z.SGBSTDN_TERM_CODE_EFF <= RPRATRM_PERIOD)) CURR_MAJR,
                                   
               (SELECT MAX (SHRTGPA_TERM_CODE)
                  FROM SHRTGPA
                 WHERE     SHRTGPA_PIDM = RPRATRM_PIDM
                       AND SHRTGPA_HOURS_ATTEMPTED > 0
                       AND SHRTGPA_GPA_TYPE_IND = 'I'
                       AND SHRTGPA_TERM_CODE < RPRATRM_PERIOD) PRIOR_TERM,
                                               
               (SELECT DISTINCT 'Y'
                  FROM RPRAWRD
                 WHERE     RPRAWRD_PIDM = RPRATRM_PIDM
                       AND RPRAWRD_AIDY_CODE = :PRIOR_AIDY
                       AND RPRAWRD_FUND_CODE LIKE '_S%'
                       AND RPRAWRD_FUND_CODE <> 'GSOSCG'
                       AND RPRAWRD_PAID_AMT > 0) PD_STATE_AID,
                                                
               (SELECT MIN (SWRPRTA_ACTIVITY_DATE)
                  FROM SWRPRTA
                 WHERE     SPRIDEN_PIDM = SWRPRTA_PIDM
                       AND SWRPRTA_TERM_CODE = :PRIOR_FAL) MIN_PRTR_ACT_DT
                                                
          FROM RPRATRM
               LEFT JOIN SPRIDEN ON RPRATRM_PIDM = SPRIDEN_PIDM
               LEFT JOIN RORSTAT
                   ON     RPRATRM_PIDM = RORSTAT_PIDM
                      AND RORSTAT_AIDY_CODE = RPRATRM_AIDY_CODE
               LEFT JOIN RNVAND0
                   ON     SPRIDEN_PIDM = RNVAND0_PIDM
                      AND RPRATRM_AIDY_CODE = RNVAND0_AIDY_CODE
         WHERE     SPRIDEN_CHANGE_IND IS NULL
               AND RPRATRM_FUND_CODE = 'GSOSCG'
               AND RPRATRM_AIDY_CODE = :PRIOR_AIDY
               --AND RPRATRM_PAID_AMT > 0
               --AND RPRATRM_OFFER_AMT > 0

                                             )
