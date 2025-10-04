SELECT ID,
       NAME,
       AID_PERIOD,
       FUND,
       AWARD_STATUS,
       AWARD_OFFER_AMOUNT,
       AWARD_ACCEPT_AMOUNT,
       AWARD_PAID_AMOUNT,
       AWARD_ORIGINAL_OFFR_DATE,
       AWARD_STATUS_DATE,
       GPA,
       ACADEMIC_STUDY_VALUE,
       YEAR_IN_COLLEGE,
       YEAR_IN_COLLEGE_DESC,
       PACKAGING_GROUP,
       DATA_ITEM_1,
       INSTITUTION,
       INSTITUTION_DESC,
       INSTITUTION_TYPE,
       --INSTITUTION_TYPE_DESC,
       HS_GPA,
       SECONDARY_DIPLOMA,
       SECONDARY_DIPLOMA_DESC,
       --OFFICIAL_TRANSCRIPT_IND,
       SUMMER_TIME_STATUS,
       FALL_TIME_STATUS,
       SPRING_TIME_STATUS,
       TRANSFER_GPA,
       CUM_DEGREE,
       STUDENT_TYPE,
       POST_SECONDARY_INSTITUTION_DESC,
       BACHELORS_DEGREE,
       DEGREE_DATE,
       BACHELORS_TRANSFER_GPA,
       GTGP_ROAMESG,
       ROAHSDT_ADMISSION_TEST_IND
       
  FROM (SELECT 
               DISTINCT SPRIDEN_ID                                       AS ID,
               SPRIDEN_LAST_NAME || ', ' || SPRIDEN_FIRST_NAME           AS NAME,
               RPRATRM_PERIOD                                            AS AID_PERIOD,
               RPRAWRD_FUND_CODE                                         AS FUND,
               RPRAWRD_AWST_CODE                                         AS AWARD_STATUS,
               RPRAWRD_OFFER_AMT                                         AS AWARD_OFFER_AMOUNT,
               RPRAWRD_ACCEPT_AMT                                        AS AWARD_ACCEPT_AMOUNT,
               RPRAWRD_PAID_AMT                                          AS AWARD_PAID_AMOUNT,
               RPRAWRD_ORIG_OFFER_DATE                                   AS AWARD_ORIGINAL_OFFR_DATE,
               RPRAWRD_AWST_DATE                                         AS AWARD_STATUS_DATE,
               SHRLGPA_GPA                                               AS GPA,
               SHRLGPA_LEVL_CODE                                         AS ACADEMIC_STUDY_VALUE,
               RCRAPP3_YR_IN_COLL_2                                      AS YEAR_IN_COLLEGE,
               RCRAPP1_YR_IN_COLL                                        AS YEAR_IN_COLLEGE_DESC,
               RORSTAT_PGRP_CODE                                         AS PACKAGING_GROUP,
               
               CASE WHEN RPRAWRD_AWST_CODE = 'OFRD' THEN '3'
               WHEN RPRAWRD_AWST_CODE = 'ACPT' THEN '1'
               WHEN RPRAWRD_AWST_CODE = 'WCPT' THEN '2'
               ELSE '0'
                                                                     END AS DATA_ITEM_1,

               H.STVSBGI_CODE                                            AS INSTITUTION,
               H.STVSBGI_DESC                                            AS INSTITUTION_DESC,
               H.STVSBGI_TYPE_IND                                        AS INSTITUTION_TYPE,
               --                                                        AS INSTITUTION_TYPE_DESC,              
               SORHSCH_GPA                                               AS HS_GPA,
               STVDPLM_CODE                                              AS SECONDARY_DIPLOMA,
               STVDPLM_DESC                                              AS SECONDARY_DIPLOMA_DESC,
               --                                                        AS OFFICIAL_TRANSCRIPT_IND,
               CASE 
               WHEN P.RORENRL_FINAID_ADJ_HR > 11 THEN 'FT'
               WHEN P.RORENRL_FINAID_ADJ_HR BETWEEN 9 AND 11 THEN 'TT'
               WHEN P.RORENRL_FINAID_ADJ_HR BETWEEN 6 AND 8 THEN 'HT'   
               WHEN P.RORENRL_FINAID_ADJ_HR <= 5 THEN 'LH'   
               ELSE '00'                                             END AS SUMMER_TIME_STATUS,
               
                CASE 
               WHEN Q.RORENRL_FINAID_ADJ_HR > 11 THEN 'FT'
               WHEN Q.RORENRL_FINAID_ADJ_HR BETWEEN 9 AND 11 THEN 'TT'
               WHEN Q.RORENRL_FINAID_ADJ_HR BETWEEN 6 AND 8 THEN 'HT'   
               WHEN Q.RORENRL_FINAID_ADJ_HR <= 5 THEN 'LH'  
               ELSE '00'                                             END AS FALL_TIME_STATUS,
               
                CASE 
               WHEN R.RORENRL_FINAID_ADJ_HR > 11 THEN 'FT'
               WHEN R.RORENRL_FINAID_ADJ_HR BETWEEN 9 AND 11 THEN 'TT'
               WHEN R.RORENRL_FINAID_ADJ_HR BETWEEN 6 AND 8 THEN 'HT'   
               WHEN R.RORENRL_FINAID_ADJ_HR <= 5 THEN 'LH'   
               ELSE '00'                                             END AS SPRING_TIME_STATUS,
               
               N.SORDEGR_GPA_TRANSFERRED                                 AS TRANSFER_GPA,
               N.SORDEGR_SBGI_CODE                                       AS CUM_DEGREE,
               SGBSTDN_STYP_CODE                                         AS STUDENT_TYPE,
               I.STVSBGI_DESC                                            AS POST_SECONDARY_INSTITUTION_DESC,
               M.SORDEGR_DEGC_CODE                                       AS BACHELORS_DEGREE,
               M.SORDEGR_DEGC_DATE                                       AS DEGREE_DATE,
               M.SORDEGR_GPA_TRANSFERRED                                 AS BACHELORS_TRANSFER_GPA,
               RORMESG_MESG_CODE                                         AS GTGP_ROAMESG,
               RORHSDT_ADMISSION_TEST_IND                                AS ROAHSDT_ADMISSION_TEST_IND
               
          FROM RORSTAT
               
               LEFT JOIN SPRIDEN
                   ON     SPRIDEN_PIDM = RORSTAT_PIDM
                      AND SPRIDEN_CHANGE_IND IS NULL
               
               LEFT JOIN RPRAWRD
               ON RPRAWRD_PIDM = RORSTAT_PIDM
               AND RPRAWRD_AIDY_CODE = :AIDY
               AND RPRAWRD_ORIG_OFFER_AMT > 0
                      
               LEFT JOIN RCRAPP1
               ON RORSTAT_PIDM = RCRAPP1_PIDM
               AND RCRAPP1_AIDY_CODE = :AIDY
               AND RCRAPP1_INFC_CODE = 'EDE'
               AND RCRAPP1_CURR_REC_IND = 'Y'
               
               LEFT JOIN RCRAPP3
               ON RCRAPP1_PIDM = RCRAPP3_PIDM
               AND RCRAPP1_AIDY_CODE = RCRAPP3_AIDY_CODE
               AND RCRAPP1_INFC_CODE = RCRAPP3_INFC_CODE
               
               LEFT JOIN RPRATRM 
               ON RPRAWRD_PIDM = RPRATRM_PIDM
               AND RPRAWRD_AIDY_CODE = RPRATRM_AIDY_CODE
               AND RPRATRM_PERIOD = :CUR_TERM 
                      
               LEFT JOIN RORENRL P
               ON RORSTAT_PIDM = P.RORENRL_PIDM
               AND P.RORENRL_TERM_CODE = :SUM_TRM
                         
               LEFT JOIN RORENRL Q
               ON RORSTAT_PIDM = Q.RORENRL_PIDM
               AND Q.RORENRL_TERM_CODE = :FAL_TRM
               
               LEFT JOIN RORENRL R
               ON RORSTAT_PIDM = R.RORENRL_PIDM
               AND R.RORENRL_TERM_CODE = :SPR_TRM
                                                               
               LEFT JOIN RORHSDT 
               ON RORHSDT_PIDM = RORSTAT_PIDM
               
               LEFT JOIN SGBSTDN 
               ON SGBSTDN_PIDM = RORSTAT_PIDM
               
               LEFT JOIN STVMAJR A
                   ON SGBSTDN_MAJR_CODE_CONC_1 = A.STVMAJR_CODE
                   
               LEFT JOIN STVMAJR B
                   ON SGBSTDN_MAJR_CODE_CONC_2 = B.STVMAJR_CODE
                   
               LEFT JOIN SORDEGR N
                   ON     N.SORDEGR_PIDM = RORSTAT_PIDM
                      AND RORSTAT_AIDY_CODE = :AIDY
                      AND (   N.SORDEGR_SBGI_CODE = 'CUMGPA'
                           OR N.SORDEGR_DEGC_CODE = 'CUMGPA')
                           
               LEFT JOIN SORDEGR M
                   ON     M.SORDEGR_PIDM = RORSTAT_PIDM
                      AND RORSTAT_AIDY_CODE = :AIDY
                      AND (   M.SORDEGR_DEGC_CODE = 'NB'
                           OR M.SORDEGR_DEGC_CODE LIKE 'B%')
                      AND M.SORDEGR_DEGC_DATE IS NOT NULL
                      
               LEFT JOIN STVSBGI H
               ON H.STVSBGI_CODE = M.SORDEGR_SBGI_CODE
               AND H.STVSBGI_TYPE_IND = 'H'
                              
               LEFT JOIN STVSBGI I
               ON I.STVSBGI_CODE = M.SORDEGR_SBGI_CODE
               AND I.STVSBGI_TYPE_IND <> 'H'
               
               LEFT JOIN SORHSCH
                   ON     RORSTAT_PIDM = SORHSCH_PIDM
                   AND SORHSCH_GRADUATION_DATE IS NOT NULL
                      
               LEFT JOIN STVDPLM
               ON SORHSCH_VPDI_CODE = STVDPLM_VPDI_CODE

               LEFT JOIN RORMESG
                   ON     RORMESG_PIDM = RORSTAT_PIDM
                      AND RORMESG_AIDY_CODE = RORSTAT_AIDY_CODE
                      AND RORMESG_MESG_CODE LIKE 'GTGP'
                      
               LEFT JOIN SHRLGPA E
                   ON     E.SHRLGPA_PIDM = RORSTAT_PIDM
                      AND E.SHRLGPA_GPA_TYPE_IND = 'O'
                                                                                        
         WHERE     RORSTAT_AIDY_CODE = :AIDY
              
               AND SGBSTDN_TERM_CODE_EFF =
                   (SELECT MAX (Z.SGBSTDN_TERM_CODE_EFF)
                      FROM SGBSTDN Z
                     WHERE     Z.SGBSTDN_PIDM = SPRIDEN_PIDM
                           AND Z.SGBSTDN_TERM_CODE_EFF >= :CUR_TERM
                           AND SGBSTDN_STST_CODE = 'AS')
               AND RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTU1','GFUTG1')
                      AND RPRAWRD_AWST_CODE IN ('OFRD','ACPT','WCPT')
                      AND (SHRLGPA_GPA <3.25 OR SHRLGPA_GPA IS NULL))
                      