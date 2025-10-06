SELECT SPRIDEN_ID,
       SPBPERS_SSN,
       SPRIDEN_FIRST_NAME,
       SPRIDEN_LAST_NAME,
       OCOG,
       OCOG_OFFER_AMT,
       OCOG_CANCEL_AMT,
       KC_UG_BILLED,
       RC_UG_BILLED,
       RCRAPP2_PELL_PGI,
       RORSTAT_PCKG_COMP_DATE,
       ETV_MESG,
       VET_CODE,
       BEGIN_DATE,
       END_DATE,
       SERDTSR_TERM_CODE_EFF,
       VERIF,
       VERIF_STATUS,
       GORM_MESG,
       GORF_MESG,
       GORS_MESG,
       Total_Tuition_Charges,
       Career_Service_Fee,
       RB_AMT_TOTAL,
       RBF_AMT_TOTAL,
       MAX_STU_TYPE,
       MAX_STU_LEVEL,
       TBUGHRS_R,
       TBUGHRS_K,
       TBUGHRS_X,
       TRUGHRS_R,
       TRUGHRS_K,
       TRUGHRS_X,
       PELL_EFC_COMBO,
       units_used
       
  FROM (SELECT SPRIDEN_ID,
               SPBPERS_SSN,
               SPRIDEN_FIRST_NAME,
               SPRIDEN_LAST_NAME,
               OCOG,
               OCOG_OFFER_AMT,
               OCOG_CANCEL_AMT,
               KC_UG_BILLED,
               RC_UG_BILLED,
               RCRAPP2_PELL_PGI,
               RORSTAT_PCKG_COMP_DATE,
               ETV_MESG,
               VET_CODE,
               BEGIN_DATE,
               END_DATE,
               SERDTSR_TERM_CODE_EFF,
               VERIF,
               VERIF_STATUS,
               GORM_MESG,
               GORF_MESG,
               GORS_MESG,
               Total_Tuition_Charges,
               Career_Service_Fee,
               RB_AMT_TOTAL,
               RBF_AMT_TOTAL,
               MAX_STU_TYPE,
               MAX_STU_LEVEL,
               TBUGHRS_R,
               TBUGHRS_K,
               TBUGHRS_X,
               TRUGHRS_R,
               TRUGHRS_K,
               TRUGHRS_X,
               (CASE
                    WHEN     NVL (TBUGHRS_K, 0) > 0
                         AND NVL (TBUGHRS_R, 0) > 0
                         AND NVL (TBUGHRS_X, 0) >= 12
                    THEN
                        '3248'
                    WHEN     NVL (TBUGHRS_K, 0) > 0
                         AND NVL (TBUGHRS_R, 0) > 0
                         AND NVL (TBUGHRS_X, 0) BETWEEN 09 AND 11
                    THEN
                        '2436'
                    WHEN     NVL (TBUGHRS_K, 0) > 0
                         AND NVL (TBUGHRS_R, 0) > 0
                         AND NVL (TBUGHRS_X, 0) BETWEEN 06 AND 08
                    THEN
                        '1624'
                    WHEN     NVL (TBUGHRS_K, 0) > 0
                         AND NVL (TBUGHRS_R, 0) > 0
                         AND NVL (TBUGHRS_X, 0) BETWEEN 01 AND 05
                    THEN
                        '812'
                END)    PELL_EFC_COMBO,
               units_used
               
          FROM (SELECT SPRIDEN_ID,
                       SPBPERS_SSN,
                       SPRIDEN_FIRST_NAME,
                       SPRIDEN_LAST_NAME,
                       RPRATRM_FUND_CODE                              OCOG,
                       RPRATRM_OFFER_AMT                              OCOG_OFFER_AMT,
                       RPRATRM_CANCEL_AMT                             OCOG_CANCEL_AMT,
                           
                       (SELECT SUM (SFRSTCR_BILL_HR)
                          FROM SFRSTCR
                         WHERE     RORSTAT_PIDM = SFRSTCR_PIDM
                               AND SFRSTCR_TERM_CODE = :PERIOD
                               AND SFRSTCR_CAMP_CODE = 'KC'
                               AND SFRSTCR_LEVL_CODE = 'UG')          KC_UG_BILLED,
                               
                       (SELECT SUM (SFRSTCR_BILL_HR)
                          FROM SFRSTCR
                         WHERE     RORSTAT_PIDM = SFRSTCR_PIDM
                               AND SFRSTCR_TERM_CODE = :PERIOD
                               AND SFRSTCR_CAMP_CODE <> 'KC'
                               AND SFRSTCR_LEVL_CODE = 'UG')          RC_UG_BILLED,
                               
                       RCRAPP2_PELL_PGI,
                       RORSTAT_PCKG_COMP_DATE,
                       A.RORMESG_MESG_CODE                            ETV_MESG,
                       SERDTSR_SSER_CODE                              VET_CODE,
                       SERDTSR_BEGIN_DATE                             BEGIN_DATE,
                       SERDTSR_END_DATE                               END_DATE,
                       SERDTSR_TERM_CODE_EFF,
                       RRRAREQ_TREQ_CODE                              VERIF,
                       RRRAREQ_TRST_CODE                              VERIF_STATUS,
                       B.RORMESG_MESG_CODE                            GORM_MESG,
                       C.RORMESG_MESG_CODE                            GORF_MESG,
                       D.RORMESG_MESG_CODE                            GORS_MESG,
                       
                       (SELECT SUM (TBRACCD_AMOUNT)
                          FROM TBRACCD
                         WHERE     RORSTAT_PIDM = TBRACCD_PIDM
                               AND TBRACCD_TERM_CODE = :PERIOD
                               AND TBRACCD_DETAIL_CODE LIKE 'T%')    Total_Tuition_Charges,
                               
                       (SELECT SUM (TBRACCD_AMOUNT)
                          FROM TBRACCD
                         WHERE     RORSTAT_PIDM = TBRACCD_PIDM
                               AND TBRACCD_TERM_CODE = :PERIOD
                               AND TBRACCD_DETAIL_CODE IN ('FKCS', 'FRCS')) Career_Service_Fee,
                               
                       (SELECT 
                          SUM (CASE WHEN RBRAPBC_PBCP_CODE = 'R+B' THEN RBRAPBC_AMT ELSE 0 END) AS TOT_RB
                         FROM RBRAPBC
                        WHERE     RBRAPBC_PIDM = RORSTAT_PIDM
                               AND RBRAPBC_PERIOD = :PERIOD
                               AND RBRAPBC_RUN_NAME = 'ACTUAL'
                               AND RBRAPBC_PBTP_CODE = 'COA'
                               AND RBRAPBC_AIDY_CODE = :AIDY
                               AND RBRAPBC_PBCP_CODE ='R+B') RB_AMT_TOTAL,
                               
                       (SELECT
                          SUM (CASE WHEN RBRAPBC_PBCP_CODE = 'R+BF' THEN RBRAPBC_AMT ELSE 0 END) AS TOT_RBF
                         FROM RBRAPBC
                        WHERE     RBRAPBC_PIDM = RORSTAT_PIDM
                               AND RBRAPBC_PERIOD = :PERIOD
                               AND RBRAPBC_RUN_NAME = 'ACTUAL'
                               AND RBRAPBC_PBTP_CODE = 'COA'
                               AND RBRAPBC_AIDY_CODE = :AIDY
                               AND RBRAPBC_PBCP_CODE ='R+BF') RBF_AMT_TOTAL,
                               
                       (SELECT SGBSTDN_STYP_CODE
                          FROM SGBSTDN
                         WHERE     RORSTAT_PIDM = SGBSTDN_PIDM
                               AND SGBSTDN_TERM_CODE_EFF =
                                   (SELECT MAX (A.SGBSTDN_TERM_CODE_EFF)
                                      FROM SGBSTDN A
                                     WHERE A.SGBSTDN_PIDM = RORSTAT_PIDM)) MAX_STU_TYPE,
                                     
                       (SELECT SGBSTDN_LEVL_CODE
                          FROM SGBSTDN
                         WHERE     RORSTAT_PIDM = SGBSTDN_PIDM
                               AND SGBSTDN_TERM_CODE_EFF =
                                   (SELECT MAX (A.SGBSTDN_TERM_CODE_EFF)
                                      FROM SGBSTDN A
                                     WHERE A.SGBSTDN_PIDM = RORSTAT_PIDM)) MAX_STU_LEVEL,
                                     
                       (SELECT SUM (SFRSTCR_BILL_HR)
                          FROM SFRSTCR
                         WHERE     SFRSTCR_RSTS_CODE NOT IN ('RA', 'WA')
                               AND SFRSTCR_LEVL_CODE = 'UG'
                               AND SFRSTCR_PIDM = RORSTAT_PIDM
                               AND SFRSTCR_CAMP_CODE <> 'KC'
                               AND SFRSTCR_TERM_CODE = :PERIOD)            TBUGHRS_R,
                               
                       (SELECT SUM (SFRSTCR_BILL_HR)
                          FROM SFRSTCR
                         WHERE     SFRSTCR_RSTS_CODE NOT IN ('RA', 'WA')
                               AND SFRSTCR_LEVL_CODE = 'UG'
                               AND SFRSTCR_PIDM = RORSTAT_PIDM
                               AND SFRSTCR_CAMP_CODE = 'KC'
                               AND SFRSTCR_TERM_CODE = :PERIOD)            TBUGHRS_K,
                               
                       (SELECT SUM (SFRSTCR_BILL_HR)
                          FROM SFRSTCR
                         WHERE     SFRSTCR_RSTS_CODE NOT IN ('RA', 'WA')
                               AND SFRSTCR_LEVL_CODE = 'UG'
                               AND SFRSTCR_PIDM = RORSTAT_PIDM
                               AND SFRSTCR_TERM_CODE = :PERIOD)            TBUGHRS_X,
                               
                       (SELECT SUM (SFRSTCR_credit_HR)
                          FROM SFRSTCR
                         WHERE     SFRSTCR_RSTS_CODE NOT IN ('RA', 'WA')
                               AND SFRSTCR_LEVL_CODE = 'UG'
                               AND SFRSTCR_PIDM = RORSTAT_PIDM
                               AND SFRSTCR_CAMP_CODE <> 'KC'
                               AND SFRSTCR_TERM_CODE = :PERIOD)            TRUGHRS_R,
                               
                       (SELECT SUM (SFRSTCR_CREDIT_HR)
                          FROM SFRSTCR
                         WHERE     SFRSTCR_RSTS_CODE NOT IN ('RA', 'WA')
                               AND SFRSTCR_LEVL_CODE = 'UG'
                               AND SFRSTCR_PIDM = RORSTAT_PIDM
                               AND SFRSTCR_CAMP_CODE = 'KC'
                               AND SFRSTCR_TERM_CODE = :PERIOD)            TRUGHRS_K,
                               
                       (SELECT SUM (SFRSTCR_CREDIT_HR)
                          FROM SFRSTCR
                         WHERE     SFRSTCR_RSTS_CODE NOT IN ('RA', 'WA')
                               AND SFRSTCR_LEVL_CODE = 'UG'
                               AND SFRSTCR_PIDM = RORSTAT_PIDM
                               AND SFRSTCR_TERM_CODE = :PERIOD)            TRUGHRS_X, 
                               
                       TOT_GRANT_UNIT                                      units_used
                       
                  FROM RORSTAT
                       LEFT JOIN SPRIDEN
                           ON     RORSTAT_PIDM = SPRIDEN_PIDM
                              AND SPRIDEN_CHANGE_IND IS NULL
                              
                       LEFT JOIN SPBPERS ON RORSTAT_PIDM = SPBPERS_PIDM
                       
                       LEFT JOIN SERDTSR
                           ON     RORSTAT_PIDM = SERDTSR_PIDM
                              AND SERDTSR_SSER_CODE IN ('VTR1','VTR2','VTR3','VTR6')
                              AND SERDTSR_TERM_CODE_EFF = :PERIOD
                              
                       LEFT JOIN RCRAPP1
                           ON     RORSTAT_PIDM = RCRAPP1_PIDM
                              AND RORSTAT_AIDY_CODE = RCRAPP1_AIDY_CODE
                              AND RCRAPP1_INFC_CODE = 'EDE'
                              AND RCRAPP1_CURR_REC_IND = 'Y'
                              
                       LEFT JOIN RCRAPP2
                           ON     RCRAPP1_PIDM = RCRAPP2_PIDM
                              AND RCRAPP1_AIDY_CODE = RCRAPP2_AIDY_CODE
                              AND RCRAPP1_INFC_CODE = RCRAPP2_INFC_CODE
                              AND RCRAPP1_SEQ_NO = RCRAPP2_SEQ_NO
                              
                       LEFT JOIN RPRATRM
                           ON     RORSTAT_PIDM = RPRATRM_PIDM
                              AND RPRATRM_FUND_CODE IN ('GSNOCG','GSNOCR','GSNOCX','GSNO2E')
                              AND RORSTAT_AIDY_CODE = RPRATRM_AIDY_CODE
                              AND RPRATRM_PERIOD = :PERIOD
                              
                       LEFT JOIN RORMESG A
                           ON     RORSTAT_PIDM = A.RORMESG_PIDM
                              AND RORSTAT_AIDY_CODE = A.RORMESG_AIDY_CODE
                              AND A.RORMESG_MESG_CODE = 'SEIN'
                              AND UPPER (A.RORMESG_FULL_DESC) LIKE '%ETV%'
                              
                       LEFT JOIN RORMESG B
                           ON     RORSTAT_PIDM = B.RORMESG_PIDM
                              AND RORSTAT_AIDY_CODE = B.RORMESG_AIDY_CODE
                              AND B.RORMESG_MESG_CODE = 'GORM'
                              
                       LEFT JOIN RORMESG C
                           ON     RORSTAT_PIDM = C.RORMESG_PIDM
                              AND RORSTAT_AIDY_CODE = C.RORMESG_AIDY_CODE
                              AND C.RORMESG_MESG_CODE = 'GORF'
                              
                       LEFT JOIN RORMESG D
                           ON     RORSTAT_PIDM = D.RORMESG_PIDM
                              AND RORSTAT_AIDY_CODE = D.RORMESG_AIDY_CODE
                              AND D.RORMESG_MESG_CODE = 'GORS'
                              
                       LEFT JOIN RRRAREQ
                           ON     RORSTAT_PIDM = RRRAREQ_PIDM
                              AND RORSTAT_AIDY_CODE = RRRAREQ_AIDY_CODE
                              AND RRRAREQ_TREQ_CODE = 'VERIF'
                              
                       LEFT JOIN KSUAPPS.RWTOCOG
                           ON     SPBPERS_SSN = SSN
                              AND RORSTAT_AIDY_CODE = AIDY_CODE
                              
                 WHERE RORSTAT_AIDY_CODE = :AIDY AND RCRAPP2_PELL_PGI <= 2190)
         
               WHERE (VET_CODE IS NOT NULL OR ETV_MESG IS NOT NULL)
                 AND RC_UG_BILLED >= NVL (KC_UG_BILLED, 0))
