SELECT *

FROM 

(SELECT DISTINCT SPRIDEN_ID               ID,
       SPRIDEN_FIRST_NAME       FIRST_NAME,
       SPRIDEN_LAST_NAME        LAST_NAME,
       RCRAPP1_CURR_REC_IND     FAFSA_IND,
       RORSTAT_APRD_CODE        APRD,
       RORSTAT_PGRP_CODE        PGRP,
       RORSTAT_PCKG_COMP_DATE   PCKG_DATE,
       RORSTAT_PCKG_REQ_COMP_DATE    PCKG_REQ_COMP_DATE,
       
       (SELECT SGBSTDN_STYP_CODE
          FROM SGBSTDN
         WHERE RORSTAT_PIDM = SGBSTDN_PIDM
          AND SGBSTDN_TERM_CODE_EFF =
         (SELECT MAX (A.SGBSTDN_TERM_CODE_EFF)
          FROM SGBSTDN A
          WHERE A.SGBSTDN_PIDM = RORSTAT_PIDM
          AND A.SGBSTDN_TERM_CODE_EFF <= :SPR_TERM)) STU_TYPE,
                           
       SHRLGPA_HOURS_EARNED     UG_HOURS_EARNED,
       
       (SELECT SGBSTDN_LEVL_CODE
          FROM SGBSTDN
         WHERE RORSTAT_PIDM = SGBSTDN_PIDM
         AND SGBSTDN_TERM_CODE_EFF =
         (SELECT MAX (B.SGBSTDN_TERM_CODE_EFF)
         FROM SGBSTDN B
         WHERE B.SGBSTDN_PIDM = RORSTAT_PIDM))      MAX_STU_LEVEL,
                     
       SGBSTDN_PROGRAM_1,
       SGBSTDN_PROGRAM_2,   
       D.RORSAPR_SAPR_CODE     SUMMER_SAP,
       E.RORSAPR_SAPR_CODE     FALL_SAP,
       F.RORSAPR_SAPR_CODE     SPR_SAP,
       
      (SELECT SUM(RPRATRM_OFFER_AMT)
              FROM RPRATRM
              WHERE RPRATRM_AIDY_CODE = :AIDY
              AND RPRATRM_PERIOD = :SMR_TERM
              AND RPRATRM_OFFER_AMT > 0
              AND (
                   RPRATRM_FUND_CODE LIKE 'LFN%' OR 
                   RPRATRM_FUND_CODE LIKE 'LFUU%'
                   )
              AND RPRATRM_PIDM = RORSTAT_PIDM
      ) AS SUMMER_DL_OFFERED,

      (SELECT SUM(RPRATRM_ACCEPT_AMT)
              FROM RPRATRM
              WHERE RPRATRM_AIDY_CODE = :AIDY
              AND RPRATRM_PERIOD = :SMR_TERM
              AND RPRATRM_OFFER_AMT > 0
              AND (
                   RPRATRM_FUND_CODE LIKE 'LFN%' OR 
                   RPRATRM_FUND_CODE LIKE 'LFUU%'
                   )
              AND RPRATRM_PIDM = RORSTAT_PIDM
      ) AS SUMMER_DL_ACCEPTED,
     
      (SELECT SUM(RPRATRM_PAID_AMT)
              FROM RPRATRM
              WHERE RPRATRM_AIDY_CODE = :AIDY
              AND RPRATRM_PERIOD = :SMR_TERM
              AND RPRATRM_OFFER_AMT > 0
              AND (
                   RPRATRM_FUND_CODE LIKE 'LFN%' OR 
                   RPRATRM_FUND_CODE LIKE 'LFUU%'
                   )
              AND RPRATRM_PIDM = RORSTAT_PIDM
      ) AS SUMMER_DL_PAID,
               
       (SELECT SUM (RPRATRM_OFFER_AMT)
          FROM RPRATRM
         WHERE     RPRATRM_AIDY_CODE = :AIDY
               AND RPRATRM_PERIOD = :FAL_TERM
               AND RPRATRM_OFFER_AMT > 0
               AND (   RPRATRM_FUND_CODE LIKE 'LFN%'
                    OR RPRATRM_FUND_CODE LIKE 'LFUU%')
               AND RPRATRM_PIDM = RORSTAT_PIDM
        ) FALL_DL_OFFERED,
        
      (SELECT SUM(RPRATRM_ACCEPT_AMT)
              FROM RPRATRM
              WHERE RPRATRM_AIDY_CODE = :AIDY
              AND RPRATRM_PERIOD = :FAL_TERM
              AND RPRATRM_OFFER_AMT > 0
              AND (
                   RPRATRM_FUND_CODE LIKE 'LFN%' OR 
                   RPRATRM_FUND_CODE LIKE 'LFUU%'
                   )
              AND RPRATRM_PIDM = RORSTAT_PIDM
      ) AS FALL_DL_ACCEPTED,
               
       (SELECT SUM (RPRATRM_OFFER_AMT)
          FROM RPRATRM
         WHERE     RPRATRM_AIDY_CODE = :AIDY
               AND RPRATRM_PERIOD = :SPR_TERM
               AND RPRATRM_OFFER_AMT > 0
               AND (   RPRATRM_FUND_CODE LIKE 'LFN%'
                    OR RPRATRM_FUND_CODE LIKE 'LFUU%')
               AND RPRATRM_PIDM = SPRIDEN_PIDM
         ) SPRING_DL_OFFERED,
         
      (SELECT SUM(RPRATRM_ACCEPT_AMT)
              FROM RPRATRM
              WHERE RPRATRM_AIDY_CODE = :AIDY
              AND RPRATRM_PERIOD = :SPR_TERM
              AND RPRATRM_OFFER_AMT > 0
              AND (
                   RPRATRM_FUND_CODE LIKE 'LFN%' OR 
                   RPRATRM_FUND_CODE LIKE 'LFUU%'
                   )
              AND RPRATRM_PIDM = RORSTAT_PIDM
      ) AS SPRING_DL_ACCEPTED,
               
       (SELECT SUM (SFRSTCR_CREDIT_HR)
          FROM SFRSTCR
         WHERE     SFRSTCR_PIDM = RORSTAT_PIDM
               AND SFRSTCR_TERM_CODE = :SMR_TERM
               AND SFRSTCR_RSTS_CODE IN ('RR','RE','RW','R2')) SMR_HRS,
               
       (SELECT SUM (SFRSTCR_CREDIT_HR)
          FROM SFRSTCR
         WHERE     SFRSTCR_PIDM = RORSTAT_PIDM
               AND SFRSTCR_TERM_CODE = :FAL_TERM
               AND SFRSTCR_RSTS_CODE IN ('RR','RE','RW','R2')) FAL_HRS,
               
       (SELECT SUM (SFRSTCR_CREDIT_HR)
          FROM SFRSTCR
         WHERE     SFRSTCR_PIDM = RORSTAT_PIDM
               AND SFRSTCR_TERM_CODE = :SPR_TERM
               AND SFRSTCR_RSTS_CODE IN ('RR','RE', 'RW', 'R2')) SPR_HRS,
               
       ROBUSDF_VALUE_201,
       RRRAREQ_TREQ_CODE        SMRDLR,
       RRRAREQ_TRST_CODE        SMRDLR_STATUS,
       RRRAREQ_STAT_DATE        SMRDLR_STATUS_DATE,
       LDLM.RORMESG_MESG_CODE        LDLM_MESSAGE,
       LDLM.RORMESG_EXPIRATION_DATE  LDLM_EXP_DATE,
       RHRCOMM_CATEGORY_CODE    UGGR_RHACOMM,
       RHRCOMM_ACTIVITY_DATE    UGGR_ACTVTY_DATE,
       UNES.RORMESG_MESG_CODE        UNES_MESSAGE,
       UNES.RORMESG_EXPIRATION_DATE  UNES_EXP_DATE,
       (
       SELECT SFRTHST_TMST_CODE
        FROM 
          (SELECT SFRTHST_TMST_CODE
           FROM SFRTHST
           WHERE RORSTAT_PIDM = SFRTHST_PIDM
           AND  SFRTHST_TERM_CODE = :SMR_TERM
        ORDER BY SFRTHST_ACTIVITY_DATE DESC )
        WHERE ROWNUM = 1) SMR_TIME_STATUS,
                           
       (
       SELECT SFRTHST_TMST_CODE
        FROM 
          (SELECT SFRTHST_TMST_CODE
           FROM SFRTHST
           WHERE RORSTAT_PIDM = SFRTHST_PIDM
           AND  SFRTHST_TERM_CODE = :FAL_TERM
        ORDER BY SFRTHST_ACTIVITY_DATE DESC )
        WHERE ROWNUM = 1) FAL_TIME_STATUS,
                           
       (
       SELECT SFRTHST_TMST_CODE
        FROM 
          (SELECT SFRTHST_TMST_CODE
           FROM SFRTHST
           WHERE RORSTAT_PIDM = SFRTHST_PIDM
           AND  SFRTHST_TERM_CODE = :SPR_TERM
        ORDER BY SFRTHST_ACTIVITY_DATE DESC )
        WHERE ROWNUM = 1) SPR_TIME_STATUS

  FROM RORSTAT
  
       LEFT JOIN SPRIDEN
           ON RORSTAT_PIDM = SPRIDEN_PIDM 
           AND SPRIDEN_CHANGE_IND IS NULL
           
       LEFT JOIN SHRLGPA
           ON     SHRLGPA_PIDM = RORSTAT_PIDM
              AND SHRLGPA_LEVL_CODE = 'UG'
              AND SHRLGPA_GPA_TYPE_IND = 'O'
       
       LEFT JOIN RORMESG LDLM
           ON     LDLM.RORMESG_PIDM = RORSTAT_PIDM
           AND    LDLM.RORMESG_AIDY_CODE = RORSTAT_AIDY_CODE
           AND    LDLM.RORMESG_MESG_CODE = 'LDLM'
           
        LEFT JOIN RORMESG UNES
           ON     UNES.RORMESG_PIDM = RORSTAT_PIDM
           AND    UNES.RORMESG_AIDY_CODE = RORSTAT_AIDY_CODE
           AND    UNES.RORMESG_MESG_CODE = 'UNES'

       LEFT JOIN ROBUSDF
           ON     RORSTAT_PIDM = ROBUSDF_PIDM
              AND RORSTAT_AIDY_CODE = ROBUSDF_AIDY_CODE
              
       LEFT JOIN RCRAPP1
           ON     RORSTAT_PIDM = RCRAPP1_PIDM
              AND RORSTAT_AIDY_CODE = RCRAPP1_AIDY_CODE
              AND RCRAPP1_INFC_CODE = 'EDE'
              AND RCRAPP1_CURR_REC_IND = 'Y'
              
       LEFT JOIN RCRAPP2
           ON     RORSTAT_PIDM = RCRAPP2_PIDM
              AND RORSTAT_AIDY_CODE = RCRAPP2_AIDY_CODE
              AND RCRAPP2_INFC_CODE = 'EDE'
              AND RCRAPP1_SEQ_NO = RCRAPP2_SEQ_NO
              
       LEFT JOIN RCRLDS4
           ON     RORSTAT_PIDM = RCRLDS4_PIDM
              AND RCRLDS4_CURR_REC_IND = 'Y'
              AND RCRLDS4_AIDY_CODE = RORSTAT_AIDY_CODE
              
       LEFT JOIN RORSAPR D
           ON     RORSTAT_PIDM = D.RORSAPR_PIDM
              AND D.RORSAPR_TERM_CODE = :SMR_TERM
              
       LEFT JOIN RORSAPR E
           ON     RORSTAT_PIDM = E.RORSAPR_PIDM
              AND E.RORSAPR_TERM_CODE = :FAL_TERM
              
       LEFT JOIN RORSAPR F
           ON     RORSTAT_PIDM = F.RORSAPR_PIDM
              AND F.RORSAPR_TERM_CODE = :SPR_TERM
              
       LEFT JOIN RORENRL
           ON     RORSTAT_PIDM = RORENRL_PIDM
              AND RORENRL_TERM_CODE IN ( :SMR_TERM, :FAL_TERM, :SPR_TERM)
              
       LEFT JOIN RRRAREQ
           ON     RORSTAT_PIDM = RRRAREQ_PIDM
              AND RRRAREQ_TREQ_CODE = 'SMRDLR'
              AND RRRAREQ_AIDY_CODE = RORSTAT_AIDY_CODE
       LEFT JOIN SGBSTDN ON SGBSTDN_PIDM = RORSTAT_PIDM
       
       LEFT JOIN RHRCOMM
           ON    RHRCOMM_PIDM = RORSTAT_PIDM
             AND RHRCOMM_AIDY_CODE = RORSTAT_AIDY_CODE
             AND RHRCOMM_CATEGORY_CODE = 'UGGR'
       
 WHERE     RORSTAT_AIDY_CODE = :AIDY
       AND RORSTAT_APRD_CODE NOT LIKE 'CPM%'
       AND RORSTAT_PCKG_COMP_DATE IS NOT NULL
       AND RCRAPP1_CURR_REC_IND = 'Y'
       AND SGBSTDN_TERM_CODE_EFF =
           (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
              FROM SGBSTDN Z
             WHERE     Z.SGBSTDN_PIDM = RORSTAT_PIDM
                   AND Z.SGBSTDN_TERM_CODE_EFF <= :SPR_TERM))

WHERE NOT (ROBUSDF_VALUE_201 IS NULL AND SMR_TIME_STATUS = 'LH')
