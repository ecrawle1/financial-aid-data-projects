-- SANITIZED PUBLIC VERSION
-- Direct student/borrower identifiers and hard-coded student data have been removed from public output.
-- Literal student ID/SSN lists have been replaced with bind parameters where applicable.
-- Schema fields may remain internally where required for joins, filtering, or comparison logic.
-- Do not commit query results or exports containing student records.

WITH  MAX_RORSAPR AS
(
    SELECT
        RORSAPR_PIDM,
        RORSAPR_TERM_CODE,
        RORSAPR_SAPR_CODE,
        RTVSAPR_DESC,
        ROW_NUMBER() OVER
        (
            PARTITION BY RORSAPR_PIDM
            ORDER BY RORSAPR_TERM_CODE DESC
        ) AS RN
    FROM RORSAPR
    LEFT JOIN RTVSAPR
    ON RTVSAPR_CODE = RORSAPR_SAPR_CODE
    WHERE RORSAPR_TERM_CODE <= :SPR_TERM
),

  
BASE AS
 (SELECT NULL AS STUDENT_ID,
               NULL AS STUDENT_FIRST_NAME,
               NULL AS STUDENT_LAST_NAME,
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
                                   
               FE.RORENRL_FINAID_ADJ_HR                                 FEDAID_FINAID_ADJ,
               FE.RORENRL_CONSORTIUM_IND                                CONSORTIUM_IND,
               FE.RORENRL_FINAID_BILL_HR                                FEDAID_BILL_HR,
               SE.RORENRL_FINAID_BILL_HR                                STANDARD_BILL_HR,
               B.RPRATRM_FUND_CODE,
               RPRAWRD_AWST_CODE,
               B.RPRATRM_OFFER_AMT                                      CUR_TERM_OFFER,
               B.RPRATRM_ACCEPT_AMT                                     CUR_TERM_ACCEPT,
               B.RPRATRM_PAID_AMT                                       CUR_TERM_PAID,
               
               (SELECT SUM (A.RPRATRM_PAID_AMT)
                  FROM RPRATRM A
                 WHERE     A.RPRATRM_PIDM = B.RPRATRM_PIDM
                       AND A.RPRATRM_TERM_CODE = :FAL_TERM)             CUR_TERM_PAID_AID,
                       
               RPRAWRD_OFFER_AMT                                        YEAR_OFFER,
               MAX_RORSAPR.RORSAPR_TERM_CODE,
               MAX_RORSAPR.RORSAPR_SAPR_CODE
               
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
                      
               LEFT JOIN RORENRL FE
                   ON     B.RPRATRM_PIDM = FE.RORENRL_PIDM
                      AND B.RPRATRM_PERIOD = FE.RORENRL_TERM_CODE
                      AND FE.RORENRL_ENRR_CODE = 'FEDAID'
                      
               LEFT JOIN RORENRL SE
                   ON     B.RPRATRM_PIDM = SE.RORENRL_PIDM
                      AND B.RPRATRM_PERIOD = SE.RORENRL_TERM_CODE
                      AND SE.RORENRL_ENRR_CODE = 'STANDARD'
                      
               LEFT JOIN  MAX_RORSAPR
                   ON    RPRATRM_PIDM =  RORSAPR_PIDM
                   AND MAX_RORSAPR.RN = 1
                      
         WHERE     B.RPRATRM_FUND_CODE LIKE 'LF%'
               AND B.RPRATRM_PERIOD = :FAL_TERM
    )
    
SELECT *

FROM BASE
               
 WHERE NVL(FAL_TMST, '00') = '00'
       AND CUR_TERM_OFFER > 0
       AND NVL (CUR_TERM_PAID, 0) = 0