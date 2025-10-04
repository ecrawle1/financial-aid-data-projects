SELECT *
  
  FROM (SELECT SPRIDEN_ID,
               SPRIDEN_FIRST_NAME,
               SPRIDEN_LAST_NAME,
               RORSTAT_APRD_CODE,
               
    ( SELECT SFRTHST_TMST_CODE
      FROM (SELECT SFRTHST_TMST_CODE
              FROM SFRTHST
             WHERE RORSTAT_PIDM = SFRTHST_PIDM
              AND  SFRTHST_TERM_CODE = :SMR_TERM
          ORDER BY SFRTHST_ACTIVITY_DATE DESC )
          WHERE ROWNUM = 1) SMR_TMST,
             
    ( SELECT SFRTHST_TMST_CODE
      FROM (SELECT SFRTHST_TMST_CODE
              FROM SFRTHST
             WHERE RORSTAT_PIDM = SFRTHST_PIDM
              AND  SFRTHST_TERM_CODE = :FAL_TERM
          ORDER BY SFRTHST_ACTIVITY_DATE DESC )
          WHERE ROWNUM = 1) FAL_TMST,
          
    ( SELECT SFRTHST_TMST_CODE
      FROM (SELECT SFRTHST_TMST_CODE
              FROM SFRTHST
             WHERE RORSTAT_PIDM = SFRTHST_PIDM
              AND  SFRTHST_TERM_CODE = :SPR_TERM
          ORDER BY SFRTHST_ACTIVITY_DATE DESC )
          WHERE ROWNUM = 1) SPR_TMST,
                                   
               RORENRL_FINAID_ADJ_HR                                    FROZEN_REPEAT,
               RORENRL_CONSORTIUM_IND                                   CONSORTIUM,
               B.RPRATRM_FUND_CODE,
               RPRAWRD_AWST_CODE,
               B.RPRATRM_OFFER_AMT                                      CUR_TERM_OFFER,
               B.RPRATRM_ACCEPT_AMT                                     CUR_TERM_ACCEPT,
               B.RPRATRM_PAID_AMT                                       CUR_TERM_PAID,
               
               (SELECT SUM (A.RPRATRM_PAID_AMT)
                  FROM RPRATRM A
                 WHERE     A.RPRATRM_PIDM = B.RPRATRM_PIDM
                       AND A.RPRATRM_TERM_CODE = :CUR_TRM)             CUR_TERM_PAID_AID,
                       
               RPRAWRD_OFFER_AMT                                        YEAR_OFFER
               
          FROM RPRATRM  B
               LEFT JOIN SPRIDEN
                   ON     B.RPRATRM_PIDM = SPRIDEN_PIDM
                      AND SPRIDEN_CHANGE_IND IS NULL
                      
               LEFT JOIN RPRAWRD
                   ON     B.RPRATRM_PIDM = RPRAWRD_PIDM
                      AND B.RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
                      AND RPRAWRD_AIDY_CODE = :AIDY
                      
               LEFT JOIN RORSTAT
                   ON     B.RPRATRM_PIDM = RORSTAT_PIDM
                      AND RORSTAT_AIDY_CODE = :AIDY
                      
               LEFT JOIN RORENRL
                   ON     B.RPRATRM_PIDM = RORENRL_PIDM
                      AND B.RPRATRM_PERIOD = RORENRL_TERM_CODE
                      AND RORENRL_ENRR_CODE = 'REPEAT'
                      
         WHERE     B.RPRATRM_FUND_CODE LIKE 'LF%'
               AND B.RPRATRM_PERIOD = :CUR_TRM
    )
               
 WHERE NVL (SMR_TMST, '00') = '00'
       AND CUR_TERM_OFFER > 0
       AND NVL (CUR_TERM_PAID, 0) = 0