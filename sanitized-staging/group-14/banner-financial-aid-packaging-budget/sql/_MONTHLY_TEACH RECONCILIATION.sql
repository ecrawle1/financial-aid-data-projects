/*
FERPA-SAFE PUBLIC VERSION
Direct student/borrower identifiers have been removed or masked from the final result set where practical.
Hard-coded student IDs, SSNs, personal email values, individualized free-text output, and staff user identifiers were removed or parameterized where applicable.
Schema fields may remain internally where required for joins, filtering, calculation, or comparison logic.
This repository contains SQL code only. Do not commit query output or student-level data.
*/

SELECT NULL AS PIDM,
       NULL                                      AS ID,
       NULL                                      AS TAX_ID,
       NULL                                      AS FNAME,
       NULL                                      AS LNAME,
       RPRAWRD_FUND_CODE                         FUND_CODE,
       RPRAWRD_OFFER_AMT                         OFFER_YEAR,
       RPRAWRD_ACCEPT_AMT                        ACCEPT_YEAR,
       RPRAWRD_CANCEL_AMT                        CANCEL_YEAR,
       RPRAWRD_DECLINE_AMT                       DECLINE_YEAR,
       RPRAWRD_PAID_AMT                          PAID_YEAR,
      
       (SELECT RPRATRM_OFFER_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :SMR_TRM)    SMR_OFFER,
              
       (SELECT RPRATRM_ACCEPT_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :SMR_TRM)    SMR_ACCEPT,
              
       (SELECT RPRATRM_CANCEL_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :SMR_TRM)    SMR_CANCEL,
              
       (SELECT RPRATRM_DECLINE_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :SMR_TRM)    SMR_DECLINE,
              
       (SELECT RPRATRM_PAID_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :SMR_TRM)    SMR_PAID,
              
       (SELECT RPRATRM_OFFER_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :FAL_TRM)    FAL_OFFER,
              
       (SELECT RPRATRM_ACCEPT_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :FAL_TRM)    FAL_ACCEPT,
              
       (SELECT RPRATRM_CANCEL_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :FAL_TRM)    FAL_CANCEL,
              
       (SELECT RPRATRM_DECLINE_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :FAL_TRM)    FAL_DECLINE,
              
       (SELECT RPRATRM_PAID_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :FAL_TRM)    FAL_PAID,
              
       (SELECT RPRATRM_OFFER_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :SPR_TRM)    SPR_OFFER,
              
       (SELECT RPRATRM_ACCEPT_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :SPR_TRM)    SPR_ACCEPT,
              
       (SELECT RPRATRM_CANCEL_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :SPR_TRM)    SPR_CANCEL,
              
       (SELECT RPRATRM_DECLINE_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :SPR_TRM)    SPR_DECLINE,
              
       (SELECT RPRATRM_PAID_AMT
          FROM RPRATRM
         WHERE     RPRATRM_PIDM = RPRAWRD_PIDM
               AND RPRATRM_FUND_CODE = RPRAWRD_FUND_CODE
               AND RPRATRM_PERIOD = :SPR_TRM)    SPR_PAID
              
  FROM RPRAWRD
       LEFT JOIN SPRIDEN
           ON     RPRAWRD_PIDM = SPRIDEN_PIDM
              AND SPRIDEN_CHANGE_IND IS NULL
             
       LEFT JOIN SPBPERS ON RPRAWRD_PIDM = SPBPERS_PIDM
      
 WHERE     RPRAWRD_AIDY_CODE = :AIDY
       AND RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTGG')
       AND RPRAWRD_OFFER_AMT > 0
      
 ORDER BY 1