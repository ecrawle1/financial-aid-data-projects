SELECT SPRIDEN_ID                       ID,
       SPRIDEN_LAST_NAME                LNAME,
       SPRIDEN_FIRST_NAME               FNAME,
       RORSTAT_APRD_CODE                APRD,
       CASE WHEN RORSTAT_APPL_RCVD_DATE IS NOT NULL 
         THEN 'Y' 
         ELSE 'N' 
         END                         AS FAFSA_IND,
       RORSTAT_PCKG_COMP_DATE           PCKG_COMP_DATE,
       RORENRL_FINAID_ADJ_HR            SMR_RPT_FZNHRS,
       
       (SELECT SUM(RPRATRM_OFFER_AMT)
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :SMR_TRM
               AND RPRATRM_OFFER_AMT > 0) SMR_OFRD_AID,
               
       (SELECT SUM(RPRATRM_PAID_AMT)
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :SMR_TRM
               AND RPRATRM_PAID_AMT > 0) SMR_PAID_AID,
               
       (SELECT DISTINCT 'Y'
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :SMR_TRM
               AND RPRATRM_OFFER_AMT > 0
               AND RPRATRM_FUND_CODE = 'GFNPEL') SMR_PELL,
               
       (SELECT DISTINCT 'Y'
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :SMR_TRM
               AND RPRATRM_OFFER_AMT > 0
               AND RPRATRM_FUND_CODE IN ('GSNOCG', 'GSNO2E')) SMR_OCOG,
               
       (SELECT DISTINCT 'Y'
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :SMR_TRM
               AND RPRATRM_OFFER_AMT > 0
               AND RPRATRM_FUND_CODE IN ('GFUTGU', 'GFUTGG')) SMR_TCH,
               
       (SELECT DISTINCT 'Y'
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :SMR_TRM
               AND RPRATRM_OFFER_AMT > 0
               AND RPRATRM_FUND_CODE LIKE 'JFN%') SMR_FWS,
               
       (SELECT DISTINCT 'Y'
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :SMR_TRM
               AND RPRATRM_OFFER_AMT > 0
               AND (    RPRATRM_FUND_CODE LIKE 'LF%'
                    AND (    RPRATRM_FUND_CODE NOT LIKE 'LFUP%'
                         AND RPRATRM_FUND_CODE NOT LIKE 'LFUG%'))) SMR_DL,
                         
       (SELECT DISTINCT 'Y'
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :SMR_TRM
               AND RPRATRM_OFFER_AMT > 0
               AND (   RPRATRM_FUND_CODE LIKE 'LFUP%'
                    OR RPRATRM_FUND_CODE LIKE 'LFUG%')) SMR_PLUS,
                    
       (SELECT DISTINCT 'Y'
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :SMR_TRM
               AND RPRATRM_OFFER_AMT > 0
               AND RPRATRM_FUND_CODE LIKE 'LEU%') SMR_ALTLN,
               
       (SELECT DISTINCT 'Y'
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :SMR_TRM
               AND RPRATRM_OFFER_AMT > 0
               AND (   RPRATRM_FUND_CODE LIKE 'GI%'
                    OR RPRATRM_FUND_CODE LIKE 'GP%')) SMR_INST_GRNT,
                    
       (SELECT DISTINCT 'Y'
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :SMR_TRM
               AND RPRATRM_OFFER_AMT > 0
               AND (   RPRATRM_FUND_CODE LIKE 'SI%'
                    OR RPRATRM_FUND_CODE LIKE 'SP%')) SMR_INST_SCH,
                    
       (SELECT SUM(RPRATRM_OFFER_AMT)
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :FAL_TRM
               AND RPRATRM_OFFER_AMT > 0) FAL_OFRD_AID,
               
       (SELECT SUM(RPRATRM_ACCEPT_AMT)
          FROM RPRATRM
         WHERE     RORSTAT_PIDM = RPRATRM_PIDM
               AND RPRATRM_PERIOD = :FAL_TRM
               AND RPRATRM_FUND_CODE IN ('LFNSA1','LFUUA1','LFUUA2','LFNPRK','LFUPA1','LFUGP1')
               AND RPRATRM_ACCEPT_AMT > 0) FAL_LN_ACPT_AID,
               
       RBRAPBG_PBGP_CODE            SMR_PBGP_CODE,
       
       (SELECT SUM(RBRAPBC_AMT)
          FROM RBRAPBC
         WHERE     RBRAPBC_PIDM = RORSTAT_PIDM
               AND RBRAPBC_AIDY_CODE = :AIDY
               AND RBRAPBC_PERIOD = :SMR_TRM
               AND RBRAPBC_RUN_NAME = 'ACTUAL'
               AND RBRAPBC_PBTP_CODE = 'COA') SMR_BUDGET_AMT,
               
       (SELECT SUM(RBRAPBC_AMT)
          FROM RBRAPBC
         WHERE     RBRAPBC_PIDM = RORSTAT_PIDM
               AND RBRAPBC_AIDY_CODE = :AIDY
               AND RBRAPBC_PERIOD = :FAL_TRM
               AND RBRAPBC_RUN_NAME = 'ACTUAL'
               AND RBRAPBC_PBTP_CODE = 'COA') FAL_BUDGET_AMT,
               
       (SELECT SUM(RBRAPBC_AMT)
          FROM RBRAPBC
         WHERE     RBRAPBC_PIDM = RORSTAT_PIDM
               AND RBRAPBC_AIDY_CODE = :AIDY
               AND RBRAPBC_PERIOD = :SPR_TRM
               AND RBRAPBC_RUN_NAME = 'ACTUAL'
               AND RBRAPBC_PBTP_CODE = 'COA') SPR_BUDGET_AMT,
               
       (SELECT SUM(SFRSTCR_CREDIT_HR)
          FROM SFRSTCR
         WHERE     RORSTAT_PIDM = SFRSTCR_PIDM
               AND SFRSTCR_TERM_CODE = :SMR_TRM
               AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) SMR_CURR_REG,
               
       (SELECT SUM(SFRSTCR_BILL_HR)
          FROM SFRSTCR
         WHERE     RORSTAT_PIDM = SFRSTCR_PIDM
               AND SFRSTCR_TERM_CODE = :SMR_TRM) SMR_CURR_BILL,
               --AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) SMR_CURR_BILL,
               
       (SELECT SUM(SFRSTCR_CREDIT_HR)
          FROM SFRSTCR
         WHERE     RORSTAT_PIDM = SFRSTCR_PIDM
               AND SFRSTCR_TERM_CODE = :FAL_TRM
               AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) FAL_CURR_REG,

       (SELECT SUM(SFRSTCR_BILL_HR)
          FROM SFRSTCR
         WHERE     RORSTAT_PIDM = SFRSTCR_PIDM
               AND SFRSTCR_TERM_CODE = :FAL_TRM) FAL_CURR_BILL,
               --AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) FAL_CURR_BILL,
                            
        (SELECT SFRTHST_TMST_CODE
        FROM 
          (SELECT SFRTHST_TMST_CODE
           FROM SFRTHST
           WHERE RORSTAT_PIDM = SFRTHST_PIDM
           AND  SFRTHST_TERM_CODE = :SMR_TRM
        ORDER BY SFRTHST_ACTIVITY_DATE DESC )
        WHERE ROWNUM = 1) CURR_TMST,
                           
       (SELECT MAX (SFRTHST_TMST_DATE)
          FROM SFRTHST
         WHERE SFRTHST_PIDM = RORSTAT_PIDM 
         AND SFRTHST_TERM_CODE = :SMR_TRM) MAX_TMST_DT,
         
       RORENRL_CONSORTIUM_IND            SMR_CONSORTIUM,
       D.RORSAPR_SAPR_CODE               SMR_SAP,
       E.RORSAPR_SAPR_CODE               FAL_SAP,
       F.RORSAPR_SAPR_CODE               SPR_SAP,
       R.RRRAREQ_TREQ_CODE               SULA_REQ,
       R.RRRAREQ_TRST_CODE               SULA_STATUS,
       S.RRRAREQ_TREQ_CODE               NSLD_REQ,
       S.RRRAREQ_TRST_CODE               NSLD_STATUS,
       U.RRRAREQ_TREQ_CODE               NCPROC_REQ,
       U.RRRAREQ_TREQ_CODE               NCPROC_STATUS
       
  FROM RORSTAT
       LEFT JOIN SPRIDEN
           ON RORSTAT_PIDM = SPRIDEN_PIDM 
           AND SPRIDEN_CHANGE_IND IS NULL
           
       LEFT JOIN RORENRL
           ON     RORSTAT_PIDM = RORENRL_PIDM
              AND RORENRL_TERM_CODE = :SMR_TRM
              AND RORENRL_ENRR_CODE = 'REPEAT'
              
       LEFT JOIN RBRAPBG
           ON     RORSTAT_PIDM = RBRAPBG_PIDM
              AND RORSTAT_AIDY_CODE = RBRAPBG_AIDY_CODE
              AND RBRAPBG_PERIOD = :SMR_TRM
              AND RBRAPBG_RUN_NAME = 'ACTUAL'
              
       LEFT JOIN RORSAPR D
           ON     RORSTAT_PIDM = D.RORSAPR_PIDM
              AND D.RORSAPR_TERM_CODE = :SMR_TRM
              
       LEFT JOIN RORSAPR E
           ON     RORSTAT_PIDM = E.RORSAPR_PIDM
              AND E.RORSAPR_TERM_CODE = :FAL_TRM
              
       LEFT JOIN RORSAPR F
           ON     RORSTAT_PIDM = F.RORSAPR_PIDM
              AND F.RORSAPR_TERM_CODE = :SPR_TRM
              
       LEFT JOIN RRRAREQ R
           ON     RORSTAT_PIDM = R.RRRAREQ_PIDM
              AND RORSTAT_AIDY_CODE = R.RRRAREQ_AIDY_CODE
              AND R.RRRAREQ_TREQ_CODE LIKE 'SULA%'
              
       LEFT JOIN RRRAREQ S
           ON     RORSTAT_PIDM = S.RRRAREQ_PIDM
              AND RORSTAT_AIDY_CODE = S.RRRAREQ_AIDY_CODE
              AND S.RRRAREQ_TREQ_CODE LIKE 'NSLD%'
              
       LEFT JOIN RRRAREQ U
           ON     RORSTAT_PIDM = U.RRRAREQ_PIDM
              AND RORSTAT_AIDY_CODE = U.RRRAREQ_AIDY_CODE
              AND U.RRRAREQ_TREQ_CODE LIKE 'NCPROC'
              
 WHERE     RORSTAT_AIDY_CODE = :AIDY
       AND RORSTAT_APRD_CODE IN ('SMFLSP','SMRFAL','SMRSPR','SUMMER')
       
       ORDER BY 2
