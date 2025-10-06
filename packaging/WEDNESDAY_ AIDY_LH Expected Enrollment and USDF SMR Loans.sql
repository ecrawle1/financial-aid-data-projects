SELECT spriden_id               AS ID,
       SPRIDEN_LAST_NAME        AS LNAME,
       SPRIDEN_FIRST_NAME       AS FNAME,
       ROBUSDF_VALUE_201        AS SMR_LOAN,
       
       CASE WHEN RORSTAT_XES = '4'
       THEN 'LH'
       END AS EXP_ENR_STATUS,
       
       RORSTAT_PGRP_CODE        AS PGRP_CODE,
       RORSTAT_PCKG_REQ_COMP_DATE,
       RORSTAT_PCKG_COMP_DATE,
       RCRLDS4_AGT_SUB_TOTAL    AS SUB_TOTAL,
       RCRLDS4_AGT_UNSUB_TOTAL  AS UNSUB_TOTAL,
       RCRLDS4_AGT_COMB_TOTAL   AS COMB_AGG,
       D.RORSAPR_SAPR_CODE      AS SMR_SAP,
       E.RORSAPR_SAPR_CODE      AS FAL_SAP,
       G.RORSAPR_SAPR_CODE      AS SPR_SAP,

       (SELECT SGBSTDN_STYP_CODE
          FROM SGBSTDN
         WHERE     RORSTAT_PIDM = SGBSTDN_PIDM
               AND SGBSTDN_TERM_CODE_EFF =
                   (SELECT MAX (A.SGBSTDN_TERM_CODE_EFF)
                      FROM SGBSTDN A
                     WHERE A.SGBSTDN_PIDM = RORSTAT_PIDM))    MAX_STU_TYPE,
                     
       (SELECT SGBSTDN_LEVL_CODE
          FROM SGBSTDN
         WHERE     RORSTAT_PIDM = SGBSTDN_PIDM
               AND SGBSTDN_TERM_CODE_EFF =
                   (SELECT MAX (A.SGBSTDN_TERM_CODE_EFF)
                      FROM SGBSTDN A
                     WHERE A.SGBSTDN_PIDM = RORSTAT_PIDM))     MAX_STU_LEVEL,
                     
       (SELECT SFRTHST_TMST_CODE
          FROM SFRTHST
         WHERE     RORSTAT_PIDM = SFRTHST_PIDM
               AND SFRTHST_TERM_CODE = :SMR
               AND SFRTHST_TMST_DATE =
                   (SELECT MAX (A.SFRTHST_TMST_DATE)
                      FROM SFRTHST A
                     WHERE     A.SFRTHST_TERM_CODE = :SMR
                           AND A.SFRTHST_PIDM = RORSTAT_PIDM)) SMR_TIME_STATUS,
                           
       (SELECT SFRTHST_TMST_CODE
          FROM SFRTHST
         WHERE     RORSTAT_PIDM = SFRTHST_PIDM
               AND SFRTHST_TERM_CODE = :FAL
               AND SFRTHST_TMST_DATE =
                   (SELECT MAX (A.SFRTHST_TMST_DATE)
                      FROM SFRTHST A
                     WHERE     A.SFRTHST_TERM_CODE = :FAL
                           AND A.SFRTHST_PIDM = RORSTAT_PIDM)) FAL_TIME_STATUS,
                           
       (SELECT SFRTHST_TMST_CODE
          FROM SFRTHST
         WHERE     RORSTAT_PIDM = SFRTHST_PIDM
               AND SFRTHST_TERM_CODE = :SPR
               AND SFRTHST_TMST_DATE =
                   (SELECT MAX (A.SFRTHST_TMST_DATE)
                      FROM SFRTHST A
                     WHERE     A.SFRTHST_TERM_CODE = :SPR
                           AND A.SFRTHST_PIDM = RORSTAT_PIDM)) SPR_TIME_STATUS
                           
  FROM RORSTAT
       LEFT JOIN SPRIDEN
           ON RORSTAT_PIDM = SPRIDEN_PIDM 
           AND SPRIDEN_CHANGE_IND IS NULL
           
       LEFT JOIN ROBUSDF
           ON     RORSTAT_PIDM = ROBUSDF_PIDM
              AND RORSTAT_AIDY_CODE = ROBUSDF_AIDY_CODE
              
       LEFT JOIN RORSAPR D
           ON     RORSTAT_PIDM = D.RORSAPR_PIDM
              AND D.RORSAPR_TERM_CODE = :SUM_SAP_TERM
              
       LEFT JOIN RORSAPR E
           ON     RORSTAT_PIDM = E.RORSAPR_PIDM
              AND E.RORSAPR_TERM_CODE = :FAL_SAP_TERM
              
       LEFT JOIN RORSAPR G
           ON     RORSTAT_PIDM = G.RORSAPR_PIDM
              AND G.RORSAPR_TERM_CODE = :SPR_SAP_TERM
              
       LEFT JOIN RCRLDS4
           ON     RORSTAT_PIDM = RCRLDS4_PIDM
              AND RCRLDS4_CURR_REC_IND = 'Y'
              AND RCRLDS4_AIDY_CODE = RORSTAT_AIDY_CODE
              
 WHERE RORSTAT_AIDY_CODE = :Aid_Year 
 AND RORSTAT_XES = '4' 
