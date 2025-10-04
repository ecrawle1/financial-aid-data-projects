SELECT
         ID,
         NAME,
         FUND,
         YR_OFFER,
         YR_ACCEPT,
         YR_PAID,
         TERM_OFFER,
         TERM_ACCEPT,
         TERM_PAID,
         SMR_TEACH_OFFER,
         SMR_TEACH_ACCEPT,
         SMR_TEACH_PAID,
         FAL_TEACH_OFFER,
         FAL_TEACH_ACCEPT,
         FAL_TEACH_PAID,
         SPR_TEACH_OFFER,
         SPR_TEACH_ACCEPT,
         SPR_TEACH_PAID,
         FROZEN_REPEAT_HRS,
         CALC_TEACH_FRZN_LESS_REPEAT,

         CASE WHEN (FUND IN ('GFUTGU','GFUTGG','GFUTG1','GFUTU1')
         AND CALC_TEACH_FRZN_LESS_REPEAT <> TERM_PAID 
         AND CALC_TEACH_FRZN_LESS_REPEAT <> TERM_PAID +1 
         AND CALC_TEACH_FRZN_LESS_REPEAT <> TERM_PAID -1)
         Then 'Y'
         Else 'N' 
         END AS FRZN_REPEAT_MISMATCH,
         
         FROZEN_STANDARD_HRS,
         
         CALC_TEACH_FRZN_REPEAT,
         
         CASE WHEN (FUND IN ('GFUTGU','GFUTGG','GFUTG1','GFUTU1')
         AND CALC_TEACH_FRZN_REPEAT <> TERM_PAID 
         AND CALC_TEACH_FRZN_REPEAT <> TERM_PAID +1 
         AND CALC_TEACH_FRZN_REPEAT <> TERM_PAID -1)
         Then 'Y'
         Else 'N' 
         END AS FRZN_MISMATCH,
         
         CURRENT_TIME_STATUS,
         CALC_TEACH_CURR, 
         
         CASE WHEN (FUND IN ('GFUTGU', 'GFUTGG') 
         AND (CALC_TEACH_CURR <> TERM_PAID OR CALC_TEACH_CURR <> TERM_OFFER)
         AND (CALC_TEACH_CURR <> TERM_PAID + 1 OR CALC_TEACH_CURR <> TERM_OFFER + 1)
         AND (CALC_TEACH_CURR <> TERM_PAID - 1 OR CALC_TEACH_CURR <> TERM_OFFER - 1))
         OR (FUND IN ('GFUTG1', 'GFUTU1') 
         AND (CALC_TEACH_CURR <> TERM_PAID OR CALC_TEACH_CURR <> TERM_OFFER)
         AND (CALC_TEACH_CURR <> TERM_PAID + 1 OR CALC_TEACH_CURR <> TERM_OFFER + 1)
         AND (CALC_TEACH_CURR <> TERM_PAID - 1 OR CALC_TEACH_CURR <> TERM_OFFER - 1))
         THEN 'Y'
         ELSE 'N'
         END AS CALC_CURR_MISMATCH,
                 
         SMR_LOCK,
         FAL_LOCK,
         SPR_LOCK,
         YR_LOCK,
         GTAR_ROAMESG,
         CONSORTIUM_IND,
         PAHA_ROAMESG,
         PAHM_ROAMESG,
         PAHF_ROAMESG,
         STUDRS_REQ

FROM

(SELECT
         ID,
         NAME,
         FUND,
         YR_OFFER,
         YR_ACCEPT,
         YR_PAID,
         TERM_OFFER,
         TERM_ACCEPT,
         TERM_PAID,
         SMR_TEACH_OFFER,
         SMR_TEACH_ACCEPT,
         SMR_TEACH_PAID,
         FAL_TEACH_OFFER,
         FAL_TEACH_ACCEPT,
         FAL_TEACH_PAID,
         SPR_TEACH_OFFER,
         SPR_TEACH_ACCEPT,
         SPR_TEACH_PAID,
         FROZEN_REPEAT_HRS,
         FROZEN_STANDARD_HRS,
         CURRENT_TIME_STATUS,
         CALC_TEACH_FRZN_LESS_REPEAT,
         CALC_TEACH_FRZN_REPEAT,

         CASE WHEN (FUND IN ('GFUTGU','GFUTGG','GFUTG1','GFUTU1') AND CURRENT_TIME_STATUS = 'FT') THEN 1886
         WHEN      (FUND IN ('GFUTGU','GFUTGG','GFUTG1','GFUTU1') AND CURRENT_TIME_STATUS = '3Q') THEN 1415
         WHEN      (FUND IN ('GFUTGU','GFUTGG','GFUTG1','GFUTU1') AND CURRENT_TIME_STATUS = 'HT') THEN 943
         WHEN      (FUND IN ('GFUTGU','GFUTGG','GFUTG1','GFUTU1') AND CURRENT_TIME_STATUS = 'LH') THEN 472
         ELSE (0)
         END AS CALC_TEACH_CURR,
         
         SMR_LOCK,
         FAL_LOCK,
         SPR_LOCK,
         YR_LOCK,
         CONSORTIUM_IND,
         GTAR_ROAMESG,
         PAHA_ROAMESG,
         PAHM_ROAMESG,
         PAHF_ROAMESG,
         STUDRS_REQ
         
FROM
(SELECT SPRIDEN_ID                                       AS ID,
         SPRIDEN_LAST_NAME || ', ' || SPRIDEN_FIRST_NAME  AS NAME,
         RPRAWRD_FUND_CODE                                AS FUND,
         RPRAWRD_OFFER_AMT                                AS YR_OFFER,
         RPRAWRD_ACCEPT_AMT                               AS YR_ACCEPT,
         RPRAWRD_PAID_AMT                                 AS YR_PAID,
         K.RPRATRM_OFFER_AMT                              AS TERM_OFFER,
         K.RPRATRM_ACCEPT_AMT                             AS TERM_ACCEPT,
         K.RPRATRM_PAID_AMT                               AS TERM_PAID,
         A.RPRATRM_OFFER_AMT                              AS SMR_TEACH_OFFER,
         A.RPRATRM_ACCEPT_AMT                             AS SMR_TEACH_ACCEPT,
         A.RPRATRM_PAID_AMT                               AS SMR_TEACH_PAID,
         B.RPRATRM_OFFER_AMT                              AS FAL_TEACH_OFFER,
         B.RPRATRM_ACCEPT_AMT                             AS FAL_TEACH_ACCEPT,
         B.RPRATRM_PAID_AMT                               AS FAL_TEACH_PAID,
         C.RPRATRM_OFFER_AMT                              AS SPR_TEACH_OFFER,
         C.RPRATRM_ACCEPT_AMT                             AS SPR_TEACH_ACCEPT,
         C.RPRATRM_PAID_AMT                               AS SPR_TEACH_PAID,
         N.RORENRL_FINAID_ADJ_HR                          AS FROZEN_REPEAT_HRS,
         --P.RORENRL_FINAID_ADJ_HR                          AS FAL_FROZEN_REPEAT_HRS,
         --Q.RORENRL_FINAID_ADJ_HR                          AS SPR_FROZEN_REPEAT_HRS,
         U.RORENRL_FINAID_ADJ_HR                          AS FROZEN_STANDARD_HRS,
         --S.RORENRL_FINAID_ADJ_HR                          AS FAL_FROZEN_STANDARD_HRS,
         --T.RORENRL_FINAID_ADJ_HR                          AS SPR_FROZEN_STANDARD_HRS,
         
         (SELECT SFRTHST_TMST_CODE
         FROM SFRTHST
         WHERE SFRTHST_PIDM = SPRIDEN_PIDM
         AND SFRTHST_ACTIVITY_DATE = 
             (SELECT MAX(SFRTHST_ACTIVITY_DATE)
             FROM SFRTHST Z
             WHERE Z.SFRTHST_PIDM = SPRIDEN_PIDM
             AND   Z.SFRTHST_TERM_CODE = :CUR_TRM))       AS CURRENT_TIME_STATUS,
             
         CASE WHEN (RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTU1') AND N.RORENRL_FINAID_ADJ_HR BETWEEN 12 and 50) THEN 1886
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTU1') AND N.RORENRL_FINAID_ADJ_HR  BETWEEN 9 and 11) THEN 1415
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTU1') AND N.RORENRL_FINAID_ADJ_HR  BETWEEN 6 AND 8) THEN 943
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTU1') AND N.RORENRL_FINAID_ADJ_HR  BETWEEN 1 AND 5) THEN 472
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGG','GFUTG1') AND N.RORENRL_FINAID_ADJ_HR BETWEEN 8 and 50) THEN 1886
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGG','GFUTG1') AND N.RORENRL_FINAID_ADJ_HR  BETWEEN 6 AND 7) THEN 1415
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGG','GFUTG1') AND N.RORENRL_FINAID_ADJ_HR  BETWEEN 4 AND 5) THEN 943
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGG','GFUTG1') AND N.RORENRL_FINAID_ADJ_HR BETWEEN 1 AND 3) THEN 472
         ELSE (0)
         END AS CALC_TEACH_FRZN_LESS_REPEAT,
         
         CASE WHEN (RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTU1') AND U.RORENRL_FINAID_ADJ_HR BETWEEN 12 and 50) THEN 1886
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTU1') AND U.RORENRL_FINAID_ADJ_HR  BETWEEN 9 and 11) THEN 1415
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTU1') AND U.RORENRL_FINAID_ADJ_HR  BETWEEN 6 AND 8) THEN 943
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTU1') AND U.RORENRL_FINAID_ADJ_HR  BETWEEN 1 AND 5) THEN 472
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGG','GFUTG1') AND U.RORENRL_FINAID_ADJ_HR BETWEEN 8 and 50) THEN 1886
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGG','GFUTG1') AND U.RORENRL_FINAID_ADJ_HR  BETWEEN 6 AND 7) THEN 1415
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGG','GFUTG1') AND U.RORENRL_FINAID_ADJ_HR  BETWEEN 4 AND 5) THEN 943
         WHEN (RPRAWRD_FUND_CODE IN ('GFUTGG','GFUTG1') AND U.RORENRL_FINAID_ADJ_HR BETWEEN 1 AND 3) THEN 472
         ELSE (0)
         END AS CALC_TEACH_FRZN_REPEAT,
             
         A.RPRATRM_LOCK_IND                               AS SMR_LOCK,
         B.RPRATRM_LOCK_IND                               AS FAL_LOCK,
         C.RPRATRM_LOCK_IND                               AS SPR_LOCK,
         RPRAWRD_LOCK_IND                                 AS YR_LOCK,
         N.RORENRL_CONSORTIUM_IND                         AS CONSORTIUM_IND,
         
         (SELECT RORMESG_MESG_CODE
                     FROM RORMESG
           WHERE     RORMESG_PIDM = SPRIDEN_PIDM
                 AND RORMESG_MESG_CODE = 'GTAR'
                 AND RORMESG_AIDY_CODE = :AIDY)           AS GTAR_ROAMESG,
                 
         (SELECT RORMESG_MESG_CODE
            FROM RORMESG
           WHERE     RORMESG_PIDM = SPRIDEN_PIDM
                 AND RORMESG_MESG_CODE = 'PAHA'
                 AND RORMESG_AIDY_CODE = :AIDY)           AS PAHA_ROAMESG,
         
         (SELECT RORMESG_MESG_CODE
            FROM RORMESG
           WHERE     RORMESG_PIDM = SPRIDEN_PIDM
                 AND RORMESG_MESG_CODE = 'PAHM'
                 AND RORMESG_AIDY_CODE = :AIDY)           AS PAHM_ROAMESG,
                 
         (SELECT RORMESG_MESG_CODE
            FROM RORMESG
           WHERE     RORMESG_PIDM = SPRIDEN_PIDM
                 AND RORMESG_MESG_CODE = 'PAHF'
                 AND RORMESG_AIDY_CODE = :AIDY)           AS PAHF_ROAMESG,
                 
         RRRAREQ_TREQ_CODE                                AS STUDRS_REQ
         
    FROM SPRIDEN
         LEFT JOIN RPRAWRD
             ON RPRAWRD_PIDM = SPRIDEN_PIDM 
             AND SPRIDEN_CHANGE_IND IS NULL
             
                  LEFT JOIN RPRATRM K
             ON     K.RPRATRM_PIDM = SPRIDEN_PIDM
                AND K.RPRATRM_AIDY_CODE = RPRAWRD_AIDY_CODE
                AND K.RPRATRM_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTG1','GFUTU1')
                AND K.RPRATRM_OFFER_AMT > 0
                AND K.RPRATRM_PERIOD = :CUR_TRM    
             
         LEFT JOIN RPRATRM A
             ON     A.RPRATRM_PIDM = SPRIDEN_PIDM
                AND A.RPRATRM_AIDY_CODE = RPRAWRD_AIDY_CODE
                AND A.RPRATRM_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTG1','GFUTU1')
                AND A.RPRATRM_OFFER_AMT > 0
                AND A.RPRATRM_PERIOD = :SMR_TRM
                
         LEFT JOIN RPRATRM B
             ON     B.RPRATRM_PIDM = SPRIDEN_PIDM
                AND B.RPRATRM_AIDY_CODE = RPRAWRD_AIDY_CODE
                AND B.RPRATRM_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTG1','GFUTU1')
                AND B.RPRATRM_OFFER_AMT > 0
                AND B.RPRATRM_PERIOD = :FAL_TRM
                
         LEFT JOIN RPRATRM C
             ON     C.RPRATRM_PIDM = SPRIDEN_PIDM
                AND C.RPRATRM_AIDY_CODE = RPRAWRD_AIDY_CODE
                AND C.RPRATRM_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTG1','GFUTU1')
                AND C.RPRATRM_OFFER_AMT > 0
                AND C.RPRATRM_PERIOD = :SPR_TRM
                
         LEFT JOIN RORENRL N
             ON     N.RORENRL_PIDM = SPRIDEN_PIDM
                AND N.RORENRL_ENRR_CODE = 'REPEAT'
                AND N.RORENRL_TERM_CODE = :CUR_TRM
                
        LEFT JOIN RORENRL U
             ON     U.RORENRL_PIDM = SPRIDEN_PIDM
                AND U.RORENRL_ENRR_CODE = 'STANDARD'
                AND U.RORENRL_TERM_CODE = :CUR_TRM
                
         LEFT JOIN RORENRL O
             ON     O.RORENRL_PIDM = SPRIDEN_PIDM
                AND O.RORENRL_ENRR_CODE = 'REPEAT'
                AND O.RORENRL_TERM_CODE = :SMR_TRM
                
         LEFT JOIN RORENRL P
             ON     P.RORENRL_PIDM = SPRIDEN_PIDM
                AND P.RORENRL_ENRR_CODE = 'REPEAT'
                AND P.RORENRL_TERM_CODE = :FAL_TRM
                
         LEFT JOIN RORENRL Q
             ON     Q.RORENRL_PIDM = SPRIDEN_PIDM
                AND Q.RORENRL_ENRR_CODE = 'REPEAT'
                AND Q.RORENRL_TERM_CODE = :SPR_TRM
                
         LEFT JOIN RORENRL R
             ON     R.RORENRL_PIDM = SPRIDEN_PIDM
                AND R.RORENRL_ENRR_CODE = 'STANDARD'
                AND R.RORENRL_TERM_CODE = :SMR_TRM
                
         LEFT JOIN RORENRL S
             ON     S.RORENRL_PIDM = SPRIDEN_PIDM
                AND S.RORENRL_ENRR_CODE = 'STANDARD'
                AND S.RORENRL_TERM_CODE = :FAL_TRM
                
         LEFT JOIN RORENRL T
             ON     T.RORENRL_PIDM = SPRIDEN_PIDM
                AND T.RORENRL_ENRR_CODE = 'STANDARD'
                AND T.RORENRL_TERM_CODE = :SPR_TRM
                
         LEFT JOIN RRRAREQ
             ON     SPRIDEN_PIDM = RRRAREQ_PIDM
                AND SPRIDEN_CHANGE_IND IS NULL
                AND RRRAREQ_AIDY_CODE = :AIDY
                AND RRRAREQ_TREQ_CODE = 'STUDRS'
                
   WHERE     RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTG1','GFUTU1')
         AND RPRAWRD_AIDY_CODE = :AIDY
         
ORDER BY 2))
