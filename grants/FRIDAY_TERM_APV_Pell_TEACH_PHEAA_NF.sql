SELECT ID,
       NAME,
       CRN,
       SFAREGS_CURR_TERM_HRS,
       SMR_FRZN_HRS,
       FAL_FRZN_HRS,
       SPR_FRZN_HRS,
       
       CASE
           WHEN CRN IN (CRN_1, CRN_2, CRN_3, CRN_4, CRN_5, CRN_6, CRN_7, CRN_8)
           THEN 'Y'
       END    CRN_REVIEWED,
       
       CRSE_HRS,
       CURR_PRTR,
       CURR_DT,
       LOG_PRTR,
       LOG_ACTV_DT,
       MID_GRDE,
       CURR_GRDE,
       RSTS_CDE,
       RSTS_DATE,
       CURR_DATE_DIFFERENCE,
       STRT_DT,
       PTRM_START,
       PELL_OFFER,
       TEACH_OFFER,
       PHEAA_OFFER,
       CARES_OFFER,
       SMR_OCOG_OFFER,
       SMR_OCOG_DECLINE,
       SMR_OCOG_CANCEL,
       SMR_OCOG_PAID,
       SMR_OCOG_STATUS,
       FALL_OCOG_OFFER,
       FALL_OCOG_DECLINE,
       FALL_OCOG_CANCEL,
       FALL_OCOG_PAID,
       FALL_OCOG_STATUS,
       SPR_OCOG_OFFER,
       SPR_OCOG_DECLINE,
       SPR_OCOG_CANCEL,
       SPR_OCOG_PAID,
       SPR_OCOG_STATUS,
       STCA_ACTY_DT,
       STCA_MESG,
       GPNS_MESG,
       GPNS_EXP_DT,
       IPNS_MESG,
       IPNS_EXP_DT,
       SMR_CRNS,
       SMR_CRNS2,
       FAL_CRNS,
       FAL_CRNS2,
       SPR_CRNS,
       SPR_CRNS2,
       CRN_1,
       CRN_2,
       CRN_3,
       CRN_4,
       CRN_5,
       CRN_6,
       CRN_7,
       CRN_8
       
  FROM (  SELECT DISTINCT
                 SPRIDEN_ID                                                     ID,
                 SPRIDEN_LAST_NAME ||','|| SPRIDEN_FIRST_NAME                   NAME,
                 SWRPRTR_CRN                                                    CRN,
                 SFRSTCA_CREDIT_HR                                              CRSE_HRS,
                 SWRPRTR_PRTR_CODE                                              CURR_PRTR,
                 SWRPRTR_ACTIVITY_DATE                                          CURR_DT,
                 SWRPRTA_PRTR_CODE                                              LOG_PRTR,
                 SWRPRTA_ACTIVITY_DATE                                          LOG_ACTV_DT,
                 (SELECT SUM (SFRSTCR_CREDIT_HR)
                    FROM SFRSTCR
                   WHERE     SWRPRTR_PIDM = SFRSTCR_PIDM
                         AND SFRSTCR_TERM_CODE = :TERM
                         AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2'))        SFAREGS_CURR_TERM_HRS,
                         
                 M.RORENRL_FINAID_ADJ_HR                                        SMR_FRZN_HRS,
                 N.RORENRL_FINAID_ADJ_HR                                        FAL_FRZN_HRS,
                 P.RORENRL_FINAID_ADJ_HR                                        SPR_FRZN_HRS,
                 
                 (SELECT MIN (SWRPRTA_ACTIVITY_DATE)
                    FROM SWRPRTA
                   WHERE     SWRPRTR_PIDM = SWRPRTA_PIDM
                         AND SWRPRTR_TERM_CODE = SWRPRTA_TERM_CODE
                         AND SWRPRTR_CRN = SWRPRTA_CRN
                         AND SWRPRTR_PRTR_CODE = SWRPRTA_PRTR_CODE)             MIN_PRTR_ACT_DT,
                         
                 sfrstcr_grde_code                                              FNL_GRDE,
                 sfrstcr_grde_code_mid                                          MID_GRDE,
                 (SELECT (SHRTCKG_GRDE_CODE_FINAL)
                    FROM shrtckg f
                   WHERE     SWRPRTR_PIDM = f.shrtckg_pidm
                         AND f.shrtckg_tckn_seq_no = shrtckn_seq_no
                         AND f.shrtckg_term_code = shrtckn_term_code
                         AND f.shrtckg_seq_no =
                             (SELECT MAX (shrtckg_seq_no)
                                FROM shrtckg e
                               WHERE     f.shrtckg_pidm = e.shrtckg_pidm
                                     AND f.shrtckg_term_code =
                                         e.shrtckg_term_code
                                     AND f.shrtckg_tckn_seq_no =
                                         e.shrtckg_tckn_seq_no))                CURR_GRDE,
                 sfrstcr_rsts_code                                              RSTS_CDE,
                 SFRSTCR_RSTS_DATE                                              RSTS_DATE,
                 
                 (Select TRUNC(SYSDATE - SFRSTCR_RSTS_DATE)
                 FROM SFRSTCR
                 WHERE SWRPRTR_PIDM = SFRSTCR_PIDM
                        AND SWRPRTR_TERM_CODE = SFRSTCR_TERM_CODE
                        AND SWRPRTR_CRN = SFRSTCR_CRN)                          CURR_DATE_DIFFERENCE,
                        
                 SSBSECT_LEARNER_REGSTART_FDATE                                 STRT_DT,
                 SSBSECT_PTRM_START_DATE                                        PTRM_START,
                 A.RPRATRM_OFFER_AMT                                            PELL_OFFER,
                 B.RPRATRM_OFFER_AMT                                            TEACH_OFFER,
                 C.RPRATRM_OFFER_AMT                                            PHEAA_OFFER,
                 F.RPRATRM_OFFER_AMT                                            CARES_OFFER,
                 H.RPRATRM_OFFER_AMT                                            CRRSAA_OFFER,
                 I.RPRATRM_OFFER_AMT                                            SMR_OCOG_OFFER,
                 I.RPRATRM_DECLINE_AMT                                          SMR_OCOG_DECLINE,
                 I.RPRATRM_CANCEL_AMT                                           SMR_OCOG_CANCEL,
                 I.RPRATRM_PAID_AMT                                             SMR_OCOG_PAID,
                 I.RPRATRM_AWST_CODE                                            SMR_OCOG_STATUS,
                 J.RPRATRM_OFFER_AMT                                            FALL_OCOG_OFFER,
                 J.RPRATRM_DECLINE_AMT                                          FALL_OCOG_DECLINE,
                 J.RPRATRM_CANCEL_AMT                                           FALL_OCOG_CANCEL,
                 J.RPRATRM_PAID_AMT                                             FALL_OCOG_PAID,
                 J.RPRATRM_AWST_CODE                                            FALL_OCOG_STATUS,
                 K.RPRATRM_OFFER_AMT                                            SPR_OCOG_OFFER,
                 K.RPRATRM_DECLINE_AMT                                          SPR_OCOG_DECLINE,
                 K.RPRATRM_CANCEL_AMT                                           SPR_OCOG_CANCEL,
                 K.RPRATRM_PAID_AMT                                             SPR_OCOG_PAID,
                 K.RPRATRM_AWST_CODE                                            SPR_OCOG_STATUS,
                 SFRSTCA_ACTIVITY_DATE                                          STCA_ACTY_DT,
                 SFRSTCA_MESSAGE                                                STCA_MESG,
                 D.RORMESG_FULL_DESC                                            GPNS_MESG,
                 D.RORMESG_EXPIRATION_DATE                                      GPNS_EXP_DT,
                 E.RORMESG_FULL_DESC                                            IPNS_MESG,
                 E.RORMESG_EXPIRATION_DATE                                      IPNS_EXP_DT,
                 ROBUSDF_VALUE_215                                              SMR_CRNS,
                 ROBUSDF_VALUE_216                                              SMR_CRNS2,
                 ROBUSDF_VALUE_217                                              FAL_CRNS,
                 ROBUSDF_VALUE_218                                              FAL_CRNS2,
                 ROBUSDF_VALUE_219                                              SPR_CRNS,
                 ROBUSDF_VALUE_220                                              SPR_CRNS2,
                 
                 CASE 
                      WHEN SWRPRTR_TERM_CODE = :SMR_TRM THEN SUBSTR(ROBUSDF_VALUE_215, 1, 5) --- 215 & 216 for summer NF CRN's
                      WHEN SWRPRTR_TERM_CODE = :FAL_TRM THEN SUBSTR(ROBUSDF_VALUE_217, 1, 5) --- 217 & 218 for fall NF CRN's
                      WHEN SWRPRTR_TERM_CODE = :SPR_TRM THEN SUBSTR(ROBUSDF_VALUE_219, 1, 5) --- 219 & 220 for spring NF CRN's
                      END AS CRN_1,                                                                        
                 CASE 
                      WHEN SWRPRTR_TERM_CODE = :SMR_TRM THEN SUBSTR(ROBUSDF_VALUE_215, 6, 5)
                      WHEN SWRPRTR_TERM_CODE = :FAL_TRM THEN SUBSTR(ROBUSDF_VALUE_217, 6, 5)
                      WHEN SWRPRTR_TERM_CODE = :SPR_TRM THEN SUBSTR(ROBUSDF_VALUE_219, 6, 5)
                      END AS CRN_2,
                 CASE 
                      WHEN SWRPRTR_TERM_CODE = :SMR_TRM THEN SUBSTR(ROBUSDF_VALUE_215, 11, 5)
                      WHEN SWRPRTR_TERM_CODE = :FAL_TRM THEN SUBSTR(ROBUSDF_VALUE_217, 11, 5)
                      WHEN SWRPRTR_TERM_CODE = :SPR_TRM THEN SUBSTR(ROBUSDF_VALUE_219, 11, 5)
                      END AS CRN_3,
                 CASE 
                      WHEN SWRPRTR_TERM_CODE = :SMR_TRM THEN SUBSTR(ROBUSDF_VALUE_215, 16, 5)
                      WHEN SWRPRTR_TERM_CODE = :FAL_TRM THEN SUBSTR(ROBUSDF_VALUE_217, 16, 5)
                      WHEN SWRPRTR_TERM_CODE = :SPR_TRM THEN SUBSTR(ROBUSDF_VALUE_219, 16, 5)
                      END AS CRN_4,
                 CASE 
                      WHEN SWRPRTR_TERM_CODE = :SMR_TRM THEN SUBSTR(ROBUSDF_VALUE_216, 1, 5)
                      WHEN SWRPRTR_TERM_CODE = :FAL_TRM THEN SUBSTR(ROBUSDF_VALUE_218, 1, 5)
                      WHEN SWRPRTR_TERM_CODE = :SPR_TRM THEN SUBSTR(ROBUSDF_VALUE_220, 1, 5)
                      END AS CRN_5,
                 CASE 
                      WHEN SWRPRTR_TERM_CODE = :SMR_TRM THEN SUBSTR(ROBUSDF_VALUE_216, 6, 5)
                      WHEN SWRPRTR_TERM_CODE = :FAL_TRM THEN SUBSTR(ROBUSDF_VALUE_218, 6, 5)
                      WHEN SWRPRTR_TERM_CODE = :SPR_TRM THEN SUBSTR(ROBUSDF_VALUE_220, 6, 5)
                      END AS CRN_6,
                 CASE 
                      WHEN SWRPRTR_TERM_CODE = :SMR_TRM THEN SUBSTR(ROBUSDF_VALUE_216, 11, 5)
                      WHEN SWRPRTR_TERM_CODE = :FAL_TRM THEN SUBSTR(ROBUSDF_VALUE_218, 11, 5)
                      WHEN SWRPRTR_TERM_CODE = :SPR_TRM THEN SUBSTR(ROBUSDF_VALUE_220, 11, 5)
                      END AS CRN_7,
                 CASE 
                      WHEN SWRPRTR_TERM_CODE = :SMR_TRM THEN SUBSTR(ROBUSDF_VALUE_216, 16, 5)
                      WHEN SWRPRTR_TERM_CODE = :FAL_TRM THEN SUBSTR(ROBUSDF_VALUE_218, 16, 5)
                      WHEN SWRPRTR_TERM_CODE = :SPR_TRM THEN SUBSTR(ROBUSDF_VALUE_220, 16, 5)
                      END AS CRN_8
                                      
            FROM SWRPRTR
            
                 LEFT JOIN SPRIDEN
                     ON     SWRPRTR_PIDM = SPRIDEN_PIDM
                        AND SPRIDEN_CHANGE_IND IS NULL
                        
                 LEFT JOIN SWRPRTA
                     ON     SWRPRTR_PIDM = SWRPRTA_PIDM
                        AND SWRPRTR_TERM_CODE = SWRPRTA_TERM_CODE
                        AND SWRPRTR_CRN = SWRPRTA_CRN
                        
                 LEFT JOIN SFRSTCR
                     ON     SWRPRTR_PIDM = SFRSTCR_PIDM
                        AND SWRPRTR_TERM_CODE = SFRSTCR_TERM_CODE
                        AND SWRPRTR_CRN = SFRSTCR_CRN
                        
                 LEFT JOIN ssbsect
                     ON     SWRPRTR_term_code = ssbsect_term_code
                        AND SWRPRTR_crn = ssbsect_crn
                        
                 LEFT JOIN sfrstca
                     ON     SWRPRTR_pidm = sfrstca_pidm
                        AND SWRPRTR_CRN = SFRSTCA_CRN
                        AND SWRPRTR_term_code = SFRSTCA_TERM_CODE
                        AND SFRSTCA_MESSAGE LIKE 'Final%%NF%'
                        AND SFRSTCA_SOURCE_CDE = 'BASE'
                        
                 LEFT JOIN shrtckn
                     ON     SWRPRTR_PIDM = shrtckn_pidm
                        AND SWRPRTR_term_code = SHRTCKN_TERM_CODE
                        AND SWRPRTR_crn = SHRTCKN_CRN
                        
                 LEFT JOIN RPRATRM A
                     ON     SWRPRTR_PIDM = A.RPRATRM_PIDM
                        AND A.RPRATRM_PERIOD = :TERM
                        AND A.RPRATRM_FUND_CODE = 'GFNPEL'
                        
                 LEFT JOIN RPRATRM B
                     ON     SWRPRTR_PIDM = B.RPRATRM_PIDM
                        AND B.RPRATRM_PERIOD = :TERM
                        AND B.RPRATRM_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTU1','GFUTG1')
                        
                 LEFT JOIN RPRATRM C
                     ON     SWRPRTR_PIDM = C.RPRATRM_PIDM
                        AND C.RPRATRM_PERIOD = :TERM
                        AND C.RPRATRM_FUND_CODE IN ('GSNPPP', 'GSNPPF')

                 LEFT JOIN RORENRL M
                     ON    SWRPRTR_PIDM = M.RORENRL_PIDM
                        AND M.RORENRL_TERM_CODE = :SMR_TRM
                        
                 LEFT JOIN RORENRL N
                     ON    SWRPRTR_PIDM = N.RORENRL_PIDM
                        AND N.RORENRL_TERM_CODE = :FAL_TRM
                        
                 LEFT JOIN RORENRL P
                     ON    SWRPRTR_PIDM = P.RORENRL_PIDM
                        AND P.RORENRL_TERM_CODE = :SPR_TRM   
                                   
                 LEFT JOIN RPRATRM F
                     ON     SWRPRTR_PIDM = F.RPRATRM_PIDM
                        AND F.RPRATRM_PERIOD = :TERM
                        AND F.RPRATRM_FUND_CODE = 'GFOZ19'
                        AND F.RPRATRM_OFFER_AMT > 0

                 LEFT JOIN RPRATRM H
                     ON     SWRPRTR_PIDM = H.RPRATRM_PIDM
                        AND H.RPRATRM_PERIOD = :TERM
                        AND H.RPRATRM_FUND_CODE = 'GFOZCR'
                        AND H.RPRATRM_OFFER_AMT > 0

                 LEFT JOIN RPRATRM I
                     ON     SWRPRTR_PIDM = I.RPRATRM_PIDM
                        AND I.RPRATRM_PERIOD = :SMR_TRM
                        AND I.RPRATRM_FUND_CODE IN ('GSNOCG', 'GSNOCGR','GSNO2E')
                        
                 LEFT JOIN RPRATRM J
                     ON     SWRPRTR_PIDM = J.RPRATRM_PIDM
                        AND J.RPRATRM_PERIOD = :FAL_TRM
                        AND J.RPRATRM_FUND_CODE IN ('GSNOCG', 'GSNOCGR','GSNO2E')

                 LEFT JOIN RPRATRM K
                     ON     SWRPRTR_PIDM = K.RPRATRM_PIDM
                        AND K.RPRATRM_PERIOD = :SPR_TRM
                        AND K.RPRATRM_FUND_CODE IN ('GSNOCG', 'GSNOCGR','GSNO2E')

                 LEFT JOIN RORMESG D
                     ON     SWRPRTR_PIDM = D.RORMESG_PIDM
                        AND D.RORMESG_AIDY_CODE = :AIDY
                        AND D.RORMESG_MESG_CODE = 'GPNS'
                        
                 LEFT JOIN RORMESG E
                     ON     SWRPRTR_PIDM = E.RORMESG_PIDM
                        AND E.RORMESG_AIDY_CODE = :AIDY
                        AND E.RORMESG_MESG_CODE = 'IPNS'
                        
                 LEFT JOIN ROBUSDF
                     ON     ROBUSDF_PIDM = SWRPRTR_PIDM
                        AND ROBUSDF_AIDY_CODE = :AIDY
                        
           WHERE     SWRPRTR_TERM_CODE = :TERM
                 AND (   A.RPRATRM_OFFER_AMT > 0
                      OR B.RPRATRM_OFFER_AMT > 0
                      OR C.RPRATRM_OFFER_AMT > 0)
                      
        ORDER BY 2,3,1,4,8 ASC)
                 
 WHERE (   (   (   FNL_GRDE IN ('NF','SF','W','NR','ND')
                OR MID_GRDE IN ('NF','SF','W','NR','ND'))
            OR (rsts_cde = 'W8' AND FNL_GRDE IS NULL))
        OR (CURR_PRTR = 'STARTED' AND LOG_PRTR = 'NOSTART'))
--or  (CURR_PRTR = 'NOREPORT' AND LOG_PRTR = 'NOREPORT')
--or  (CURR_PRTR = 'NOSTART' AND LOG_PRTR = 'STARTED')
--or  (CURR_PRTR = 'STARTED' AND LOG_PRTR = 'NOREPORT'))

-------and ID = '810887019'
---And CRN = '14451'
