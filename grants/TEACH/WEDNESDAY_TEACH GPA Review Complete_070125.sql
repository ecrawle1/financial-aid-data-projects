WITH
    Accepted_TEACH
    AS
        (SELECT RPRAWRD_PIDM          FUND_PIDM,
                RPRAWRD_FUND_CODE     FUND,
                RPRAWRD_OFFER_AMT     OFFER,
                RPRAWRD_AWST_CODE     AWARD_STATUS,
                RPRAWRD_AIDY_CODE     FUND_AIDY,
                CASE
                    WHEN RPRAWRD_FUND_CODE = 'GFUTGU' THEN 'UG'
                    WHEN RPRAWRD_FUND_CODE = 'GFUTGG' THEN 'GR'
                END                   AS LEVEL_CODE
           FROM RPRAWRD
          WHERE     RPRAWRD_AIDY_CODE = :AIDY
                AND RPRAWRD_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTU1','GFUTG1')
                AND RPRAWRD_AWST_CODE IN ('WCPT', 'ACPT')),
                
    NEW_FRESHMAN 
    AS  
        (   SELECT CASE WHEN SGBSTDN_STYP_CODE = 'F'
                        THEN 'NF'
                        WHEN SGBSTDN_STYP_CODE = 'T'
                        THEN 'NTF'
                        END AS NEW_FRESHMAN,
                   SGBSTDN_PIDM NF_PIDM
                 FROM SGBSTDN
                 WHERE SGBSTDN_STST_CODE = 'AS'
                 AND SGBSTDN_LEVL_CODE = 'UG'
                 AND SGBSTDN_STYP_CODE IN ('F','T')
                    AND SGBSTDN_TERM_CODE_EFF = 
                    (SELECT MAX(Z.SGBSTDN_TERM_CODE_EFF)
                    FROM SGBSTDN Z
                    WHERE Z.SGBSTDN_PIDM = SGBSTDN_PIDM 
                    AND Z.SGBSTDN_TERM_CODE_EFF IN (:SMR_TRM, :FAL_TRM, :SPR_TRM)
                    AND Z.SGBSTDN_LEVL_CODE = 'UG'
                    AND Z.SGBSTDN_STYP_CODE IN ('F','T'))),
                    
    MAX_SGBSTDN
    AS
        (  SELECT SGBSTDN_PIDM                    AS MAX_PIDM,
                  MAX (SGBSTDN_TERM_CODE_EFF)     AS MAX_TERM
             FROM SGBSTDN
            WHERE     SGBSTDN_TERM_CODE_EFF <= :SPR_TRM
                  AND SGBSTDN_STST_CODE = 'AS'
         GROUP BY SGBSTDN_PIDM),
    
    TRACKING_REQ
    AS
        (   SELECT RRRAREQ_PIDM  TREQ_PIDM,
                   RRRAREQ_TREQ_CODE GPA_REQMT,
                   RRRAREQ_TRST_CODE GPA_STATUS,
                   RRRAREQ_AIDY_CODE GPA_AIDY,
                   RRRAREQ_PERIOD    GPA_STATUS_TERM,
                   RRRAREQ_FUND_CODE
             FROM RRRAREQ
            WHERE RRRAREQ_TREQ_CODE IN ('TGGAYR', 'TGUAYR')
              AND RRRAREQ_AIDY_CODE = :AIDY
                AND RRRAREQ_TRST_CODE = 'R'),
              
    TOTAL_GPA
    AS
        (  SELECT SHRLGPA_PIDM GPA_PIDM, MAX (SHRLGPA_GPA) AS OFFICIAL_GPA_TOT
             FROM SHRLGPA
            WHERE SHRLGPA_GPA_TYPE_IND = 'O'
         GROUP BY SHRLGPA_PIDM)
         
SELECT --RORSTAT_PIDM,
       SPRIDEN_ID,
       SPRIDEN_FIRST_NAME,
       SPRIDEN_LAST_NAME,
       NF.NEW_FRESHMAN,
       RORSTAT_APRD_CODE                AID_PERIOD,
       RORSTAT_PGRP_CODE                PACKAGING_GROUP,
       AT.FUND,
       AT.AWARD_STATUS,
       AT.OFFER,
       AT.LEVEL_CODE,
       TGPA.OFFICIAL_GPA_TOT       GPA,
       RORHSDT_ADMISSION_TEST_IND       ROAHSDT_IND,
       TR.GPA_REQMT,
       TR.GPA_STATUS_TERM,
       TR.GPA_STATUS,
       N.SORDEGR_GPA_TRANSFERRED        TRANSFER_GPA,
       N.SORDEGR_SBGI_CODE              CUM_DEGREE,
       SGBSTDN_STYP_CODE                STUDENT_TYPE,
       STVSBGI_DESC                     INSTITUTION_DESC,
       M.SORDEGR_DEGC_CODE              BACHELORS_DEGREE,
       M.SORDEGR_GPA_TRANSFERRED        BACHELORS_TRANSFER_GPA,
       C.RPRATRM_OFFER_AMT              SMR_OFFER_AMT,
       C.RPRATRM_PAID_AMT               SMR_PAID_AMT,
       D.RPRATRM_OFFER_AMT              FALL_OFFER_AMT,
       D.RPRATRM_PAID_AMT               FALL_PAID_AMT,
       E.RPRATRM_OFFER_AMT              SPR_OFFER_AMT,
       E.RPRATRM_PAID_AMT               SPR_PAID_AMT
       
  FROM RORSTAT
       LEFT JOIN SPRIDEN
           ON SPRIDEN_PIDM = RORSTAT_PIDM 
           AND SPRIDEN_CHANGE_IND IS NULL
           
       LEFT JOIN RORHSDT 
       ON RORHSDT_PIDM = RORSTAT_PIDM
       
       LEFT JOIN RPRATRM C
           ON     C.RPRATRM_PIDM = RORSTAT_PIDM
              AND C.RPRATRM_AIDY_CODE BETWEEN '0001' AND :AIDY
              AND C.RPRATRM_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTU1','GFUTG1')
              AND C.RPRATRM_ORIG_OFFER_AMT > 0
              AND C.RPRATRM_PERIOD = :SMR_TRM
              
       LEFT JOIN RPRATRM D
           ON     D.RPRATRM_PIDM = RORSTAT_PIDM
              AND D.RPRATRM_AIDY_CODE BETWEEN '0001' AND :AIDY
              AND D.RPRATRM_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTU1','GFUTG1')
              AND D.RPRATRM_ORIG_OFFER_AMT > 0
              AND D.RPRATRM_PERIOD = :FAL_TRM
       
       LEFT JOIN RPRATRM E
           ON     E.RPRATRM_PIDM = RORSTAT_PIDM
              AND E.RPRATRM_AIDY_CODE BETWEEN '0001' AND :AIDY
              AND E.RPRATRM_FUND_CODE IN ('GFUTGU','GFUTGG','GFUTU1','GFUTG1')
              AND E.RPRATRM_ORIG_OFFER_AMT > 0
              AND E.RPRATRM_PERIOD = :SPR_TRM
              
       LEFT JOIN TRACKING_REQ TR
           ON TR.TREQ_PIDM = RORSTAT_PIDM
           AND TR.GPA_AIDY = RORSTAT_AIDY_CODE
           
       LEFT JOIN TOTAL_GPA TGPA
           ON TGPA.GPA_PIDM = RORSTAT_PIDM
           
       LEFT JOIN Accepted_TEACH AT
           ON AT.FUND_PIDM = RORSTAT_PIDM
           AND AT.FUND_AIDY = RORSTAT_AIDY_CODE
       
       LEFT JOIN NEW_FRESHMAN NF
           ON NF.NF_PIDM = RORSTAT_PIDM        
              
       LEFT JOIN MAX_SGBSTDN MZ 
       ON MZ.MAX_PIDM = RORSTAT_PIDM
       
       LEFT JOIN SGBSTDN
           ON     SGBSTDN_PIDM = MZ.MAX_PIDM
              AND SGBSTDN_TERM_CODE_EFF = MZ.MAX_TERM
              
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
              
        LEFT JOIN STVSBGI
           ON STVSBGI_CODE = M.SORDEGR_SBGI_CODE
           
 WHERE RORSTAT_AIDY_CODE = :AIDY 
 AND AT.FUND IN ('GFUTGU','GFUTGG','GFUTU1','GFUTG1')
 
 ORDER BY 3
 
