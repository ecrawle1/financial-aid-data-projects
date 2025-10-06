SELECT DISTINCT *
  FROM (SELECT BID,
               LNAME,
               FNAME,
               RNASL_UG_AGG,
               RNASL_GR_AGG,
               UG_OFFER,
               UG_ACPT,
               UG_PAID,
               GR_OFFER,
               GR_ACPT,
               GR_PAID,
               TOTAL_UG_AGG,
               TOTAL_GR_AGG,
               (KC_UG_TEACH + UG_OFFER)     TOTAL_KC_UG_AGG,
               (KC_GR_TEACH + GR_OFFER)     TOTAL_KC_GR_AGG,
               FUND,
               YEAR_LOCK,
               SMR_LOCK,
               FAL_LOCK,
               SPR_LOCK,
               GTAR_MSG,
               GTAR_ACTIVITY_DATE,
               GTAR_EXP_DATE
               
          FROM (SELECT SPRIDEN_ID                            BID,
                       SPRIDEN_LAST_NAME                     LNAME,
                       SPRIDEN_FIRST_NAME                    FNAME,
                       RCRLDS4_AGT_TEACH_UG_DISB_AMT         RNASL_UG_AGG,
                       RCRLDS4_AGT_TEACH_GR_DISB_AMT         RNASL_GR_AGG,
                       A.RPRAWRD_OFFER_AMT                   UG_OFFER,
                       A.RPRAWRD_ACCEPT_AMT                  UG_ACPT,
                       A.RPRAWRD_PAID_AMT                    UG_PAID,
                       B.RPRAWRD_OFFER_AMT                   GR_OFFER,
                       B.RPRAWRD_ACCEPT_AMT                  GR_ACPT,
                       B.RPRAWRD_PAID_AMT                    GR_PAID,
                       (RCRLDS4_AGT_TEACH_UG_DISB_AMT + A.RPRAWRD_OFFER_AMT)    TOTAL_UG_AGG,
                       (RCRLDS4_AGT_TEACH_GR_DISB_AMT + B.RPRAWRD_OFFER_AMT)    TOTAL_GR_AGG,
                       (SELECT SUM (RPRAWRD_PAID_AMT)
                          FROM RPRAWRD
                         WHERE     RPRAWRD_PIDM = RCRLDS4_PIDM
                               AND RCRLDS4_AIDY_CODE = :AIDY
                               --and RCRLDS4_INFC_CODE = 'EDE'
                               AND RCRLDS4_CURR_REC_IND = 'Y'
                               AND RPRAWRD_AIDY_CODE < :AIDY
                               AND RPRAWRD_FUND_CODE IN ('GFUTGU', 'GFUTU1')
                               AND RPRAWRD_PAID_AMT > 0)     KC_UG_TEACH,
                       (SELECT SUM (RPRAWRD_PAID_AMT)
                          FROM RPRAWRD
                         WHERE     RPRAWRD_PIDM = RCRLDS4_PIDM
                               AND RCRLDS4_AIDY_CODE = :AIDY
                               --and RCRLDS4_INFC_CODE = 'EDE'
                               AND RCRLDS4_CURR_REC_IND = 'Y'
                               AND RPRAWRD_AIDY_CODE < :AIDY
                               AND RPRAWRD_FUND_CODE IN ('GFUTGG', 'GFUTG1')
                               AND RPRAWRD_PAID_AMT > 0)      KC_GR_TEACH,
                       F.RPRAWRD_FUND_CODE                    FUND,
                       F.RPRAWRD_LOCK_IND                     YEAR_LOCK,
                       C.RPRATRM_LOCK_IND                     SMR_LOCK,
                       D.RPRATRM_LOCK_IND                     FAL_LOCK,
                       E.RPRATRM_LOCK_IND                     SPR_LOCK,
                       RORMESG_MESG_CODE                      GTAR_MSG,
                       RORMESG_ACTIVITY_DATE                  GTAR_ACTIVITY_DATE,
                       RORMESG_EXPIRATION_DATE                GTAR_EXP_DATE
                  
                  FROM RCRLDS4
                  
                       LEFT JOIN SPRIDEN
                           ON     SPRIDEN_PIDM = RCRLDS4_PIDM
                              AND SPRIDEN_CHANGE_IND IS NULL
                              
                       LEFT JOIN RPRAWRD A
                           ON     RCRLDS4_PIDM = A.RPRAWRD_PIDM
                              AND RCRLDS4_AIDY_CODE = A.RPRAWRD_AIDY_CODE
                              AND A.RPRAWRD_FUND_CODE IN ('GFUTGU', 'GFUTU1')
                              
                       LEFT JOIN RPRAWRD B
                           ON     RCRLDS4_PIDM = B.RPRAWRD_PIDM
                              AND RCRLDS4_AIDY_CODE = B.RPRAWRD_AIDY_CODE
                              AND B.RPRAWRD_FUND_CODE IN ('GFUTGG', 'GFUTG1')
                              
                       LEFT JOIN RPRAWRD F
                           ON     RCRLDS4_PIDM = F.RPRAWRD_PIDM
                              AND RCRLDS4_AIDY_CODE = F.RPRAWRD_AIDY_CODE
                              AND F.RPRAWRD_FUND_CODE LIKE 'GFUT%'
                              AND F.RPRAWRD_OFFER_AMT > 0
                              
                       LEFT JOIN RPRATRM C
                           ON     RCRLDS4_PIDM = C.RPRATRM_PIDM
                              AND C.RPRATRM_FUND_CODE LIKE 'GFUT%'
                              AND C.RPRATRM_OFFER_AMT > 0
                              AND C.RPRATRM_FUND_CODE = F.RPRAWRD_FUND_CODE
                              AND C.RPRATRM_PERIOD = :SMR
                              
                       LEFT JOIN RPRATRM D
                           ON     RCRLDS4_PIDM = D.RPRATRM_PIDM
                              AND D.RPRATRM_FUND_CODE LIKE 'GFUT%'
                              AND D.RPRATRM_OFFER_AMT > 0
                              AND D.RPRATRM_FUND_CODE = F.RPRAWRD_FUND_CODE
                              AND D.RPRATRM_PERIOD = :FAL
                              
                       LEFT JOIN RPRATRM E
                           ON     RCRLDS4_PIDM = E.RPRATRM_PIDM
                              AND E.RPRATRM_FUND_CODE LIKE 'GFUT%'
                              AND E.RPRATRM_OFFER_AMT > 0
                              AND E.RPRATRM_FUND_CODE = F.RPRAWRD_FUND_CODE
                              AND E.RPRATRM_PERIOD = :SPR
                              
                       LEFT JOIN RORMESG
                           ON     RCRLDS4_PIDM = RORMESG_PIDM
                              AND RCRLDS4_AIDY_CODE = RORMESG_AIDY_CODE
                              AND RORMESG_MESG_CODE = 'GTAR'
                              
                 WHERE     RCRLDS4_AIDY_CODE = :AIDY
                       --AND RCRLDS4_INFC_CODE = 'EDE'
                       AND RCRLDS4_CURR_REC_IND = 'Y'
                       AND (   A.RPRAWRD_OFFER_AMT > 0
                            OR B.RPRAWRD_OFFER_AMT > 0)))
                            
 WHERE    TOTAL_UG_AGG >= 16000
       OR TOTAL_GR_AGG >= 8000
       OR TOTAL_KC_UG_AGG >= 16000
       OR TOTAL_KC_GR_AGG >= 8000
