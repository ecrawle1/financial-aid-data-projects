SELECT SPRIDEN_PIDM,
       SPRIDEN_ID                                ID,
       SPBPERS_SSN                               TAX_ID,
       SPRIDEN_FIRST_NAME                        FNAME,
       SPRIDEN_LAST_NAME                         LNAME,
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
           ON SPRIDEN_PIDM = RPRAWRD_PIDM 
           AND SPRIDEN_CHANGE_IND IS NULL
           
       LEFT JOIN SPBPERS 
       ON SPBPERS_PIDM = RPRAWRD_PIDM
       
 WHERE     RPRAWRD_AIDY_CODE = :AIDY
       AND RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTU1','GFUTG1')
