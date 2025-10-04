            SELECT 
            DISTINCT ID, 
            LNAME, 
            FNAME, 
            TERM, 
            AID_PERIOD, 
            FUND_CODE, 
            OFRD_AMT, 
            ACPT_AMT, 
            PD_AMT, 
            LOCK_IND, 
            DISB_OVRD,
            TBUGHRS TOT_BILL_UG_HRS,
            TBUGHRS_K TOT_BILL_UG_HRS_K, 
            TBUGHRS_R TOT_BILL_UG_HRS_R,
            TBUGHRS_X TOT_BILL_UG_HRS_REG_K_R, 
            
            TBUGHRS_R - TBUGHRS_K AS RC_LESS_KC, 
            --TBUGHRS_K - TBUGHRS_R AS KC_LESS_RC,
            
            --ROUND((TBUGHRS_K/TBUGHRS_X) * 100,2) AS PERC_KC,
            --ROUND((TBUGHRS_R/TBUGHRS_X) * 100,2) AS PERC_RC,
            
            BILLABLE_CHRGES,
            
            LEAST(ROUND((TBUGHRS / 12) * 100, 2), 100) AS ENROLLMENT_INTENSITY_PCT,
            
            ROUND((7395 * ROUND(CASE WHEN TBUGHRS > 12 THEN 12 ELSE TBUGHRS END / 12, 2)) / 2, 0) AS MAX_PELL_ELIG,

            BILLABLE_CHRGES - ROUND((7395 * ROUND(CASE WHEN TBUGHRS > 12 THEN 12 ELSE TBUGHRS END / 12, 2)) / 2, 0) AS OCOG_ELIGIBILITY,
            
            (CASE
                WHEN NVL(TBUGHRS_K,0) > 0 AND NVL(TBUGHRS_R,0) > 0 AND NVL(TBUGHRS_X,0) >= 12 AND ACPT_AMT <= 2000 AND ((BILLABLE_CHRGES - 3698) >= 2000) THEN 'Y'
                WHEN NVL(TBUGHRS_K,0) > 0 AND NVL(TBUGHRS_R,0) > 0 AND NVL(TBUGHRS_X,0) BETWEEN 09 AND 11 AND ACPT_AMT <= 1500 AND ((BILLABLE_CHRGES - 2773) >= 1500) THEN 'Y'
                WHEN NVL(TBUGHRS_K,0) > 0 AND NVL(TBUGHRS_R,0) > 0 AND NVL(TBUGHRS_X,0) BETWEEN 06 AND 08 AND ACPT_AMT <= 1000 AND ((BILLABLE_CHRGES - 1849) >= 1000) THEN 'Y'
                WHEN NVL(TBUGHRS_K,0) > 0 AND NVL(TBUGHRS_R,0) > 0 AND NVL(TBUGHRS_X,0) BETWEEN 01 AND 05 AND ACPT_AMT <= 500 AND ((BILLABLE_CHRGES - 925) >= 500) THEN 'Y'   
            END) OK, 
        
            BURADJ, 
            DFOVR, 
            OCOGLMT, 
            DUAL, 
            TIME_STATUS, 
            STATUS_DATE,
        
            (CASE WHEN STATUS_DATE >= SYSDATE-7 THEN 'Y' END) STATUS_CHG,
       
            REG_ACTIVITY           
            
                FROM
                (
            SELECT SPRIDEN_ID ID, SPRIDEN_LAST_NAME LNAME, SPRIDEN_FIRST_NAME FNAME, RORSTAT_APRD_CODE AID_PERIOD, 
                    RPRATRM_PERIOD TERM, RPRATRM_FUND_CODE FUND_CODE, RPRATRM_OFFER_AMT OFRD_AMT, RPRATRM_ACCEPT_AMT ACPT_AMT, 
                    RPRATRM_PAID_AMT PD_AMT, RPRATRM_LOCK_IND LOCK_IND, RPRATRM_OVERRIDE_DISB_RULE DISB_OVRD,
                    
                    (SELECT SUM(SFRSTCR_BILL_HR)
                    FROM SFRSTCR
                    WHERE SFRSTCR_PIDM = RPRAWRD_PIDM
                    AND     SFRSTCR_TERM_CODE = :TERM
                    AND     SFRSTCR_LEVL_CODE = 'UG') TBUGHRS,
                    
                    (SELECT SUM(SFRSTCR_BILL_HR)
                    FROM SFRSTCR
                    WHERE SFRSTCR_PIDM = RPRAWRD_PIDM
                    AND     SFRSTCR_TERM_CODE = :TERM
                    AND     SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')
                    AND     SFRSTCR_CAMP_CODE = 'KC'
                    AND     SFRSTCR_LEVL_CODE = 'UG') TBUGHRS_K,
                    
                    (SELECT SUM(SFRSTCR_BILL_HR)
                    FROM SFRSTCR
                    WHERE SFRSTCR_PIDM = RPRAWRD_PIDM
                    AND     SFRSTCR_TERM_CODE = :TERM
                    AND     SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')
                    AND     SFRSTCR_CAMP_CODE <> 'KC'
                    AND     SFRSTCR_LEVL_CODE = 'UG') TBUGHRS_R,
                    
                    (SELECT SUM(SFRSTCR_BILL_HR)
                    FROM SFRSTCR
                    WHERE SFRSTCR_PIDM = RPRAWRD_PIDM
                    AND     SFRSTCR_TERM_CODE = :TERM
                    AND     SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')
                    AND     SFRSTCR_LEVL_CODE = 'UG') TBUGHRS_X,
                    
                 
                    (SELECT SUM(TBRACCD_AMOUNT)
                     FROM  TBRACCD
                     WHERE TBRACCD_PIDM = RPRAWRD_PIDM
                     AND   TBRACCD_TERM_CODE = :TERM        
                     AND (TBRACCD_DETAIL_CODE LIKE 'T%'
                     OR TBRACCD_DETAIL_CODE LIKE 'F%CS'))  BILLABLE_CHRGES,
                    
                    A.RHRCOMM_CATEGORY_CODE BURADJ, 
                    B.RHRCOMM_CATEGORY_CODE DFOVR, 
                    C.RHRCOMM_CATEGORY_CODE OCOGLMT, 
                    D.RHRCOMM_CATEGORY_CODE DUAL, 
                    
                  (SELECT 
                CASE WHEN SFRTHST_TMST_CODE = '3Q'
                     THEN 'TT'
                     WHEN SFRTHST_TMST_CODE = 'LH'
                     THEN 'QT'
                     ELSE SFRTHST_TMST_CODE
                      END SMR_TMST
                FROM
                    (SELECT SFRTHST_TMST_CODE
                       FROM SFRTHST
                      WHERE RPRAWRD_PIDM = SFRTHST_PIDM
                       AND  SFRTHST_TERM_CODE = :TERM
                   ORDER BY SFRTHST_ACTIVITY_DATE DESC)
             WHERE ROWNUM = 1 ) TIME_STATUS,

                   (SELECT MAX(SFRTHST_ACTIVITY_DATE)
                    FROM SFRTHST Z
                   WHERE Z.SFRTHST_PIDM = RPRAWRD_PIDM
                    AND     Z.SFRTHST_TERM_CODE = :TERM) STATUS_DATE,
                    
                (select DISTINCT 'Y'
                            from sfrstcr
                           where sfrstcr_pidm = RPRAWRD_pidm
                             AND SFRSTCR_TERM_CODE = :TERM
                             and sfrstcr_rsts_code in ('RE','RR','RW','R2')
                    AND    TRUNC(SFRSTCR_ACTIVITY_DATE) > SYSDATE-7) REG_ACTIVITY      

                    FROM RPRAWRD

                    LEFT JOIN SPRIDEN
                    ON          RPRAWRD_PIDM = SPRIDEN_PIDM
                    AND         SPRIDEN_CHANGE_IND IS NULL

                    left join rhrcomm a
                    on      A.RHRCOMM_PIDM = RPRAWRD_PIDM
                    AND     A.RHRCOMM_AIDY_CODE = :AIDY
                    AND     a.RHRCOMM_CATEGORY_CODE	= 'BURADJ'

                    left join rhrcomm B
                    on      B.RHRCOMM_PIDM = RPRAWRD_PIDM
                    AND     B.RHRCOMM_AIDY_CODE = :AIDY
                    AND     B.RHRCOMM_CATEGORY_CODE	= 'DFOVR'

                    left join rhrcomm C
                    on      C.RHRCOMM_PIDM = RPRAWRD_PIDM
                    AND     C.RHRCOMM_AIDY_CODE = :AIDY
                    AND     C.RHRCOMM_CATEGORY_CODE	= 'OCOGLMT'

                    left join rhrcomm D
                    on      D.RHRCOMM_PIDM = RPRAWRD_PIDM
                    AND     D.RHRCOMM_AIDY_CODE = :AIDY
                    AND     D.RHRCOMM_CATEGORY_CODE	= 'DUAL'

                    left join RPRATRM
                    on      RPRAWRD_PIDM = RPRATRM_PIDM
                    AND     RPRAWRD_AIDY_CODE = :AIDY
                    AND     RPRATRM_FUND_CODE IN ('GSNOCG','GSNOCR','GSNOCX','GSNO2E')
                    AND     RPRATRM_OFFER_AMT > 0
                    AND     RPRATRM_PERIOD = :TERM
                    
                    left join RORSTAT
                    on      RORSTAT_PIDM = RPRAWRD_PIDM
                    AND     RORSTAT_AIDY_CODE = :AIDY

                    WHERE   RPRAWRD_AIDY_CODE = :AIDY
                    AND     RPRAWRD_FUND_CODE IN ('GSNOCG', 'GSNOCR', 'GSNO2E', 'GSNOCX')
                    AND     RPRATRM_PERIOD = :TERM
                    )

                    WHERE NVL(TBUGHRS_K,0) > 0
                    AND   NVL(TBUGHRS_R,0) > 0
                    
                    ORDER BY 2