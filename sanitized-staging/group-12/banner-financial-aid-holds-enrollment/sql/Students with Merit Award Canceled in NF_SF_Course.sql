-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from public output.
-- Schema fields used internally for joins/comparisons are retained where required by query logic.
-- Do not commit query results or exports containing student records.

SELECT DISTINCT CURR_PRTR,
       LOG_PRTR,
       MID_GRDE,
       CURR_GRDE,
       RSTS_CDE,
       RSTS_DATE,
       STRT_DT,
       COURSES.COURSE_ID                                              NON_NF_SF_COURSE,
       FALL_FUND_CODE,
       FALL_MERIT_OFFER,
       FALL_MERIT_DECLINE,
       FALL_MERIT_CANCEL,
       FALL_MERIT_PAID,
       FALL_MERIT_STATUS
       
  FROM ( SELECT DISTINCT
                 SPRIDEN_PIDM                                                   PIDM,
                 SPRIDEN_ID                                                     ID,
                 SPRIDEN_LAST_NAME ||','|| SPRIDEN_FIRST_NAME                   NAME,
                 SWRPRTR_CRN                                                    CRN,
                 SWRPRTR_PRTR_CODE                                              CURR_PRTR,
                 SWRPRTR_ACTIVITY_DATE                                          CURR_DT,
                 SWRPRTA_PRTR_CODE                                              LOG_PRTR,
                 SWRPRTA_ACTIVITY_DATE                                          LOG_ACTV_DT,
                 
                 (SELECT SUM (SFRSTCR_CREDIT_HR)
                    FROM SFRSTCR
                   WHERE     SWRPRTR_PIDM = SFRSTCR_PIDM
                         AND SFRSTCR_TERM_CODE = :TERM
                         AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2'))        SFAREGS_CURR_TERM_HRS,
                         
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
                 SSBSECT_LEARNER_REGSTART_FDATE                                 STRT_DT,
                 RPRATRM_FUND_CODE                                              FALL_FUND_CODE,
                 RPRATRM_OFFER_AMT                                              FALL_MERIT_OFFER,
                 RPRATRM_DECLINE_AMT                                            FALL_MERIT_DECLINE,
                 RPRATRM_CANCEL_AMT                                             FALL_MERIT_CANCEL,
                 RPRATRM_PAID_AMT                                               FALL_MERIT_PAID,
                 RPRATRM_AWST_CODE                                              FALL_MERIT_STATUS
                 
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
                        
                 LEFT JOIN shrtckn
                     ON     SWRPRTR_PIDM = shrtckn_pidm
                        AND SWRPRTR_term_code = SHRTCKN_TERM_CODE
                        AND SWRPRTR_crn = SHRTCKN_CRN

                 LEFT JOIN RPRATRM 
                     ON     SWRPRTR_PIDM = RPRATRM_PIDM
                        AND RPRATRM_PERIOD = :FAL_TRM
                        AND RPRATRM_FUND_CODE IN ('SIM1P1', 'SIM1P2', 'SIM1A1', 'SIM1A2', 'SIM9X3', 'SIM9X4', 'SIMTA1', 'SIMTA2', 'SIMTP1', 'SIMTP2', 'SIMOR1', 'SIMOR2','SIMHD1', 'SIMHD2')
                        
                 WHERE     SWRPRTR_TERM_CODE = :TERM
                 AND       RPRATRM_OFFER_AMT > 0
                 ORDER BY 2, 3, 1, 4, 8 ASC) FUNDS

                --SUBQUERY TO SHOW STUDENT HAS BOTH COURSE WITH NF/SF AND WITHOUT
                 LEFT JOIN
                 (SELECT PIDM,
                         STUDENT_ID,
                         COURSE_ID
                  FROM (SELECT 
                         COURSE1.SFRSTCR_PIDM AS PIDM,
                         COURSE1.SPRIDEN_ID AS STUDENT_ID,
                         COURSE1.SFRSTCR_CRN AS COURSE_ID,
                         COURSE1.SFRSTCR_GRDE_CODE AS FNL_GRADE,
                         COURSE1.SFRSTCR_GRDE_CODE_MID AS MID_GRADE
                        FROM 
                         (SELECT SFRSTCR_PIDM,
                                 SFRSTCR_CRN,
                                 SFRSTCR_GRDE_CODE,
                                 SFRSTCR_GRDE_CODE_MID,
                                 SFRSTCR_TERM_CODE,
                                 SPRIDEN_ID
                           FROM SFRSTCR
                           LEFT JOIN SSBSECT
                            ON SFRSTCR_CRN = SSBSECT_CRN
                           LEFT JOIN SPRIDEN
                            ON SPRIDEN_PIDM = SFRSTCR_PIDM
                           WHERE SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE
                           AND SPRIDEN_CHANGE_IND IS NULL
                           AND (SFRSTCR_GRDE_CODE IN ('NF','SF','W','NR','ND')
                           OR SFRSTCR_GRDE_CODE_MID IN ('NF','SF','W','NR','ND')))
                                                                                  COURSE1

                  JOIN 
                       (SELECT SFRSTCR_PIDM,
                               SFRSTCR_CRN
                           FROM SFRSTCR
                           LEFT JOIN SSBSECT
                            ON SFRSTCR_CRN = SSBSECT_CRN
                           WHERE SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE
                           AND (SFRSTCR_GRDE_CODE NOT IN ('NF','SF','W','NR','ND')
                           AND SFRSTCR_GRDE_CODE_MID NOT IN ('NF','SF','W','NR','ND')))
                                                                                  COURSE2
                           ON COURSE1.SFRSTCR_PIDM = COURSE2.SFRSTCR_PIDM

                   WHERE COURSE1.SFRSTCR_TERM_CODE = :CUR_TERM
                   GROUP BY COURSE1.SFRSTCR_PIDM, COURSE1.SPRIDEN_ID, COURSE1.SFRSTCR_CRN, COURSE1.SFRSTCR_GRDE_CODE, COURSE1.SFRSTCR_GRDE_CODE_MID
                   HAVING COUNT(DISTINCT COURSE1.SFRSTCR_CRN) > 1)) 
                                                                                  COURSES
                    ON FUNDS.PIDM = COURSES.PIDM   
              
 WHERE (   (   (   FNL_GRDE IN ('NF','SF','W','NR','ND')
                OR MID_GRDE IN ('NF','SF','W','NR','ND'))
            OR (rsts_cde = 'W8' AND FNL_GRDE IS NULL))
        OR (CURR_PRTR = 'STARTED' AND LOG_PRTR = 'NOSTART'))
        
        ORDER BY FALL_FUND_CODE, CURR_PRTR