-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Literal student ID/SSN lists have been replaced with bind parameters where applicable.
-- Schema fields may remain internally where required for joins or comparison logic.
-- Do not commit query results or exports containing student records.

SELECT RORSTAT_APRD_CODE APRD, RORENRL_FINAID_ADJ_HR SMR_RPT_FZNHRS,
        
        (SELECT SUM(RPRATRM_OFFER_AMT)
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = :TERM
        AND     RPRATRM_OFFER_AMT > 0) SMR_OFRD_AID,
        
        (SELECT SUM(RPRATRM_PAID_AMT)
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = :TERM
        AND     RPRATRM_PAID_AMT > 0) SMR_PAID_AID,
        
        (SELECT distinct 'Y'
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = :TERM
        AND     RPRATRM_OFFER_AMT > 0
        AND     RPRATRM_FUND_CODE = 'GFNPEL') SMR_PELL,
        
        (SELECT distinct 'Y'
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = :TERM
        AND     RPRATRM_OFFER_AMT > 0
        AND     RPRATRM_FUND_CODE = 'GSNOCG') SMR_OCOG,
        
        (SELECT distinct 'Y'
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = :TERM
        AND     RPRATRM_OFFER_AMT > 0
        AND     RPRATRM_FUND_CODE IN ('GFUTGU','GFUTGG')) SMR_TCH,
        
        (SELECT distinct 'Y'
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = :TERM
        AND     RPRATRM_OFFER_AMT > 0
        AND     RPRATRM_FUND_CODE LIKE 'JFN%') SMR_FWS,
        
        (SELECT distinct 'Y'
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = :TERM
        AND     RPRATRM_OFFER_AMT > 0
        AND     (RPRATRM_FUND_CODE LIKE 'LF%'
        AND     (RPRATRM_FUND_CODE NOT LIKE 'LFUP%'
        AND      RPRATRM_FUND_CODE NOT LIKE 'LFUG%'))) SMR_DL,
        
        (SELECT distinct 'Y'
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = :TERM
        AND     RPRATRM_OFFER_AMT > 0
        AND     (RPRATRM_FUND_CODE LIKE 'LFUP%'
        OR      RPRATRM_FUND_CODE LIKE 'LFUG%')) SMR_PLUS,
        
        (SELECT distinct 'Y'
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = :TERM
        AND     RPRATRM_OFFER_AMT > 0
        AND     RPRATRM_FUND_CODE LIKE 'LEU%') SMR_ALTLN,
        
        (SELECT distinct 'Y'
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = :TERM
        AND     RPRATRM_OFFER_AMT > 0
        AND     (RPRATRM_FUND_CODE LIKE 'GI%'
        or      RPRATRM_FUND_CODE LIKE 'GP%')) SMR_INST_GRNT,
        
        (SELECT distinct 'Y'
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = :TERM
        AND     RPRATRM_OFFER_AMT > 0
        AND     (RPRATRM_FUND_CODE LIKE 'SI%'
        OR      RPRATRM_FUND_CODE LIKE 'SP%')) SMR_INST_SCH,
        
        (SELECT SUM(RPRATRM_OFFER_AMT)
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = '202080'
        AND     RPRATRM_OFFER_AMT > 0) FAL_OFRD_AID ,
        
        (SELECT SUM(RPRATRM_ACCEPT_AMT)
        FROM RPRATRM
        WHERE RORSTAT_PIDM = RPRATRM_PIDM
        AND     RPRATRM_PERIOD = '202080'
        AND     RPRATRM_FUND_CODE IN ('LFNSA1','LFUUA1','LFUUA2','LFNPRK','LFUPA1','LFUGP1')
        AND     RPRATRM_ACCEPT_AMT > 0) FAL_LN_ACPT_AID,
        
        RBRAPBG_PBGP_CODE SMR_PBGP_CODE,
        
        (SELECT SUM(RBRAPBC_AMT)
        FROM RBRAPBC
        WHERE RBRAPBC_PIDM = RORSTAT_PIDM
        AND     RBRAPBC_AIDY_CODE  = '2021'
        AND     RBRAPBC_PERIOD = :TERM
        AND     RBRAPBC_RUN_NAME = 'ACTUAL'
        AND     RBRAPBC_PBTP_CODE = 'COA') SMR_BUDGET_AMT,
        
        (SELECT SUM(SFRSTCR_CREDIT_HR)
        FROM SFRSTCR
        WHERE RORSTAT_PIDM = SFRSTCR_PIDM
        AND     SFRSTCR_TERM_CODE = :TERM
        AND     SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) SMR_CURR_REG,
        
        (SELECT SUM(SFRSTCR_CREDIT_HR)
        FROM SFRSTCR
        WHERE RORSTAT_PIDM = SFRSTCR_PIDM
        AND     SFRSTCR_TERM_CODE = '202080'
        AND     SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) FAL_CURR_REG,
        
        (SELECT SFRTHST_TMST_CODE
        FROM SFRTHST
        WHERE SFRTHST_PIDM = RORSTAT_PIDM
        AND     SFRTHST_TERM_CODE = :TERM
        AND     SFRTHST_TMST_DATE = 
                (SELECT MAX(SFRTHST_TMST_DATE)
                FROM SFRTHST
                WHERE SFRTHST_PIDM = RORSTAT_PIDM
                AND     SFRTHST_TERM_CODE = :TERM)) CURR_TMST,

        (SELECT MAX(SFRTHST_TMST_DATE)
                FROM SFRTHST
                WHERE SFRTHST_PIDM = RORSTAT_PIDM
                AND     SFRTHST_TERM_CODE = :TERM) MAX_TMST_DT

FROM RORSTAT

LEFT JOIN RORENRL 
ON          RORSTAT_PIDM = RORENRL_PIDM
AND         RORENRL_TERM_CODE = :TERM
AND         RORENRL_ENRR_CODE = 'REPEAT'

LEFT JOIN RBRAPBG
ON          RORSTAT_PIDM = RBRAPBG_PIDM
AND         RORSTAT_AIDY_CODE = RBRAPBG_AIDY_CODE 
AND         RBRAPBG_PERIOD = :TERM
AND         RBRAPBG_RUN_NAME = 'ACTUAL'

WHERE RORSTAT_AIDY_CODE = '2122'
AND     RORSTAT_APRD_CODE IN ('SMFLSP','SMRFAL','SMRSPR','SUMMER')
