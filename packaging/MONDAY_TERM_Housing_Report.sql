

WITH
    term_charges
    AS
        (  SELECT TBRACCD_PIDM         AS PIDM,
                  TBRACCD_TERM_CODE    AS TERM,
                  SUM(CASE WHEN TBRACCD_DETAIL_CODE LIKE 'H%' THEN TBRACCD_AMOUNT ELSE 0 END) AS H_CHARGES,
                  SUM(CASE WHEN TBRACCD_DETAIL_CODE LIKE 'M%' THEN TBRACCD_AMOUNT ELSE 0 END) AS M_CHARGES
             FROM TBRACCD
            WHERE TBRACCD_TERM_CODE IN ( :SMR_TRM, :FAL_TRM, :SPR_TRM)
            --AND   TBRACCD_AIDY_CODE = :AIDY
         GROUP BY TBRACCD_PIDM, TBRACCD_TERM_CODE),
         
    latest_sgbstdn AS (
        SELECT *
        FROM (
            SELECT SGBSTDN_PIDM AS PIDM,
                SGBSTDN_TERM_CODE_EFF,
                SGBSTDN_STYP_CODE,
                SGBSTDN_LEVL_CODE,
                SGBSTDN_PROGRAM_1,
                SGBSTDN_PROGRAM_2,
                SGBSTDN_RATE_CODE,
                ROW_NUMBER() OVER (
                    PARTITION BY SGBSTDN_PIDM
                    ORDER BY SGBSTDN_TERM_CODE_EFF DESC
                ) AS RN
            FROM SGBSTDN
            WHERE SGBSTDN_TERM_CODE_EFF <= :SPR_TRM
            AND EXISTS (
                SELECT 1 FROM RORSTAT
                WHERE RORSTAT_PIDM = SGBSTDN.SGBSTDN_PIDM
                    AND RORSTAT_AIDY_CODE = :AIDY
                )
            )
            WHERE RN = 1
        ),
         
    term_coa
    AS
        (  SELECT RBRAPBC_PIDM      AS PIDM,
                  RBRAPBC_PERIOD    AS TERM,
                  SUM (CASE WHEN RBRAPBC_PBCP_CODE = 'R+B' THEN RBRAPBC_AMT ELSE 0 END) AS TOT_RB,
                  SUM (CASE WHEN RBRAPBC_PBCP_CODE = 'R+BF' THEN RBRAPBC_AMT ELSE 0 END) AS TOT_RBF
             FROM RBRAPBC
            WHERE     RBRAPBC_PERIOD IN ( :SMR_TRM, :FAL_TRM, :SPR_TRM)
                  AND RBRAPBC_RUN_NAME = 'ACTUAL'
                  AND RBRAPBC_PBTP_CODE = 'COA'
                  AND RBRAPBC_AIDY_CODE = :AIDY
         GROUP BY RBRAPBC_PIDM, RBRAPBC_PERIOD),
         
    aidy_coa_total
    AS
        (  SELECT RBRAPBC_PIDM AS PIDM, SUM (RBRAPBC_AMT) AS TOTAL_AIDY_COA
             FROM RBRAPBC
            WHERE     RBRAPBC_AIDY_CODE = :AIDY
                  AND RBRAPBC_RUN_NAME = 'ACTUAL'
                  AND RBRAPBC_PBTP_CODE = 'COA'
                  AND RBRAPBC_AIDY_CODE = :AIDY
                  AND RBRAPBC_PERIOD IN ( :SMR_TRM, :FAL_TRM, :SPR_TRM)
         GROUP BY RBRAPBC_PIDM),
         
    aidy_awards
    AS
        (  SELECT RPRAWRD_PIDM               AS PIDM,
                  SUM (CASE WHEN RPRAWRD_FUND_CODE LIKE 'LFNS%'
                            THEN RPRAWRD_OFFER_AMT ELSE 0
                      END)                   AS SUB_OFFERED,
                  SUM (CASE WHEN RPRAWRD_FUND_CODE LIKE 'LFUU%'
                            THEN RPRAWRD_OFFER_AMT ELSE 0
                            END)             AS UNSUB_OFFERED,
                  SUM (RPRAWRD_OFFER_AMT)    AS TOTAL_OFFERED
             FROM RPRAWRD
            WHERE RPRAWRD_AIDY_CODE = :AIDY AND RPRAWRD_OFFER_AMT > 0
         GROUP BY RPRAWRD_PIDM),
         
    term_hours
    AS
        (  SELECT SFRSTCR_PIDM         AS PIDM,
                  sfrstcr_term_code    AS TERM,
                  SUM (CASE
                           WHEN SFRSTCR_RSTS_CODE IN ('RR','RE','RW','R2')
                           THEN
                               SFRSTCR_CREDIT_HR
                           ELSE 0
                       END)            AS HRS
             FROM SFRSTCR
            WHERE sfrstcr_term_code IN ( :SMR_TRM, :FAL_TRM, :SPR_TRM)
         GROUP BY SFRSTCR_PIDM, sfrstcr_term_code)       

SELECT 
       DISTINCT SPRIDEN_ID                   BNRID,
       SPRIDEN_FIRST_NAME                    F_NAME,
       SPRIDEN_LAST_NAME                     L_NAME,
       RCRAPP1_CURR_REC_IND                  FAFSA_IND,
       RORSTAT_APRD_CODE                     APRD,
       RORSTAT_PGRP_CODE                     PGRP,
       RORSTAT_PCKG_COMP_DATE                PCKG_DATE,
       RORSTAT_PCKG_REQ_COMP_DATE            PCKG_REQ_COMP_DATE,
       RCRAPP2_MODEL_CDE                     DEPENDENCY,
       sgb.SGBSTDN_STYP_CODE                 STU_TYPE,
       --SHRLGPA_HOURS_EARNED                  UG_HOURS_EARNED,
       sgb.SGBSTDN_LEVL_CODE                 MAX_STU_LEVEL,
       --sgb.SGBSTDN_PROGRAM_1                 ACAD_PROGRAM1,
       --sgb.SGBSTDN_PROGRAM_2                 ACAD_PROGRAM2,
       --D.RORSAPR_SAPR_CODE                   SUMMER_SAP,
       --E.RORSAPR_SAPR_CODE                   FALL_SAP,
       --F.RORSAPR_SAPR_CODE                   SPR_SAP,
       --sgb.SGBSTDN_RATE_CODE                 COHORT,
       --G.RPRATRM_OFFER_AMT                   SMR_OCOG_OFFER,
       --H.RPRATRM_OFFER_AMT                   SMR_SEOG_OFFER,
       tc_smr.H_CHARGES                      SMR_H_CHARGES,
       tc_smr.M_CHARGES                      SMR_M_CHARGES,
       tc_smr_coa.TOT_RB                     SMR_TOT_RB,
       tc_smr_coa.TOT_RBF                    SMR_TOT_RBF,
       --I.RPRATRM_OFFER_AMT                   FALL_OCOG_OFFER,
       --J.RPRATRM_OFFER_AMT                   FALL_SEOG_OFFER,
       tc_fal.H_CHARGES                      FAL_H_CHARGES,
       tc_fal.M_CHARGES                      FAL_M_CHARGES,
       tc_fal_coa.TOT_RB                     FAL_TOT_RB,
       tc_fal_coa.TOT_RBF                    FAL_TOT_RBF,
       --K.RPRATRM_OFFER_AMT                   SPR_OCOG_OFFER,
       --L.RPRATRM_OFFER_AMT                   SPR_SEOG_OFFER,
       tc_spr.H_CHARGES                      SPR_H_CHARGES,
       tc_spr.M_CHARGES                      SPR_M_CHARGES,
       tc_spr_coa.TOT_RB                     SPR_TOT_RB,
       tc_spr_coa.TOT_RBF                    SPR_TOT_RBF,
       --act.TOTAL_AIDY_COA                    TOTAL_AIDY_COA,
       --aa.TOTAL_OFFERED                      TOTAL_AIDY_OFFER_AMT,
       --RNVAND0_UNMET_NEED                    UNMET_NEED_AMT,
       --aa.SUB_OFFERED                        SUB_OFFERED,
       --aa.UNSUB_OFFERED                      UNSUB_OFFERED,
       --RCRLDS4_AGT_OVER_LIMIT_SUB            SUB_LOAN_LIMIT,
       --RCRLDS4_AGT_OVER_LIMIT_COMB           COMB_LOAN_LIMIT,
       --RCRLDS4_AGT_SUB_TOTAL                 TOTAL_SUB_AGG,
       --RCRLDS4_AGT_UNSUB_TOTAL               TOTAL_UNSUB_AGG,
       --RCRLDS4_AGT_COMB_TOTAL                TOTAL_COMB_AGG,
       --th_smr.HRS                            SMR_HRS,
       --th_fal.HRS                            FAL_HRS,
       --th_spr.HRS                            SPR_HRS,
       --ROBUSDF_VALUE_201,
       ROBUSDF_VALUE_202,
       ROBUSDF_VALUE_207,
       RPRINFO_CREATE_DATE                   HOUSING_RESPONSE_DATE,
       ROBUSDF_VALUE_208,
       ROBUSDF_VALUE_203,
       ROBUSDF_VALUE_204,
       ROBUSDF_VALUE_209,
       HOUS.RRRAREQ_TREQ_CODE                     HOUSING_TREQ,
       HOUS.RRRAREQ_TRST_CODE                     HOUSING_STATUS,
       HOUS.RRRAREQ_STAT_DATE                     HOUSING_STATUS_DATE,
       ZQA.RRRAREQ_TREQ_CODE                      ZQA_TREQ,
       ZQA.RRRAREQ_TRST_CODE                      ZQA_STATUS,
       ZQA.RRRAREQ_STAT_DATE                      ZQA_STATUS_DATE
       
  FROM RORSTAT
       LEFT JOIN SPRIDEN
           ON RORSTAT_PIDM = SPRIDEN_PIDM 
              AND SPRIDEN_CHANGE_IND IS NULL

       LEFT JOIN RNVAND0
           ON     RNVAND0_PIDM = RORSTAT_PIDM
              AND RNVAND0_AIDY_CODE = RORSTAT_AIDY_CODE

       LEFT JOIN RPRINFO
           ON     RPRINFO_PIDM = RORSTAT_PIDM
              AND RPRINFO_AIDY_CODE = :AIDY
              AND RPRINFO_TYPE_CODE = 'Q'
              AND RPRINFO_QUESTION_CODE = 'HOUSE'
              
       LEFT JOIN SHRLGPA
           ON     SHRLGPA_PIDM = RORSTAT_PIDM
              AND SHRLGPA_LEVL_CODE = 'UG'
              AND SHRLGPA_GPA_TYPE_IND = 'O'
              
       LEFT JOIN ROBUSDF
           ON     ROBUSDF_PIDM = RORSTAT_PIDM
              AND RORSTAT_AIDY_CODE = ROBUSDF_AIDY_CODE
              
       LEFT JOIN RCRAPP1
           ON     RORSTAT_PIDM = RCRAPP1_PIDM
              AND RORSTAT_AIDY_CODE = RCRAPP1_AIDY_CODE
              AND RCRAPP1_INFC_CODE = 'EDE'
              AND RCRAPP1_CURR_REC_IND = 'Y'
              
       LEFT JOIN RCRAPP2
           ON     RCRAPP1_PIDM = RCRAPP2_PIDM
              AND RCRAPP1_AIDY_CODE = RCRAPP2_AIDY_CODE
              AND RCRAPP2_INFC_CODE = RCRAPP1_INFC_CODE
              AND RCRAPP1_SEQ_NO = RCRAPP2_SEQ_NO
              
       LEFT JOIN RCRLDS4
           ON     RCRAPP1_PIDM = RCRLDS4_PIDM
              AND RCRLDS4_CURR_REC_IND = RCRAPP1_CURR_REC_IND
              AND RCRLDS4_INFC_CODE = RCRAPP1_INFC_CODE
              AND RCRLDS4_AIDY_CODE = RCRAPP2_AIDY_CODE
              
       LEFT JOIN RORSAPR D
           ON     RORSTAT_PIDM = D.RORSAPR_PIDM
              AND D.RORSAPR_TERM_CODE = :SMR_TRM
              
       LEFT JOIN RORSAPR E
           ON     RORSTAT_PIDM = E.RORSAPR_PIDM
              AND E.RORSAPR_TERM_CODE = :FAL_TRM
              
       LEFT JOIN RORSAPR F
           ON     RORSTAT_PIDM = F.RORSAPR_PIDM
              AND F.RORSAPR_TERM_CODE = :SPR_TRM
              
       LEFT JOIN RORENRL
           ON     RORSTAT_PIDM = RORENRL_PIDM
              AND RORENRL_TERM_CODE IN ( :SMR_TRM, :FAL_TRM, :SPR_TRM)
              
       LEFT JOIN RRRAREQ HOUS
           ON     RORSTAT_PIDM = HOUS.RRRAREQ_PIDM
              AND HOUS.RRRAREQ_TREQ_CODE = 'HOUSNG'
              AND HOUS.RRRAREQ_AIDY_CODE = RORSTAT_AIDY_CODE
              
       LEFT JOIN RRRAREQ ZQA
           ON     RORSTAT_PIDM = ZQA.RRRAREQ_PIDM
              AND ZQA.RRRAREQ_TREQ_CODE = 'ZQA'
              AND ZQA.RRRAREQ_AIDY_CODE = RORSTAT_AIDY_CODE
           
       LEFT JOIN RPRATRM G
           ON     G.RPRATRM_PIDM = RORSTAT_PIDM
              AND G.RPRATRM_PERIOD = :SMR_TRM
              AND G.RPRATRM_FUND_CODE = 'GSNO2E'
              AND G.RPRATRM_OFFER_AMT > 0
              
       LEFT JOIN RPRATRM H
           ON     H.RPRATRM_PIDM = RORSTAT_PIDM
              AND H.RPRATRM_PERIOD = :SMR_TRM
              AND H.RPRATRM_FUND_CODE = 'GFNSEO'
              AND H.RPRATRM_OFFER_AMT > 0
              
       LEFT JOIN RPRATRM I
           ON     I.RPRATRM_PIDM = RORSTAT_PIDM
              AND I.RPRATRM_PERIOD = :FAL_TRM
              AND I.RPRATRM_FUND_CODE = 'GSNO2E'
              AND I.RPRATRM_OFFER_AMT > 0
              
       LEFT JOIN RPRATRM J
           ON     J.RPRATRM_PIDM = RORSTAT_PIDM
              AND J.RPRATRM_PERIOD = :FAL_TRM
              AND J.RPRATRM_FUND_CODE = 'GFNSEO'
              AND J.RPRATRM_OFFER_AMT > 0
              
       LEFT JOIN RPRATRM K
           ON     K.RPRATRM_PIDM = RORSTAT_PIDM
              AND K.RPRATRM_PERIOD = :SPR_TRM
              AND K.RPRATRM_FUND_CODE = 'GSNO2E'
              AND K.RPRATRM_OFFER_AMT > 0
              
       LEFT JOIN RPRATRM L
           ON     L.RPRATRM_PIDM = RORSTAT_PIDM
              AND L.RPRATRM_PERIOD = :SPR_TRM
              AND L.RPRATRM_FUND_CODE = 'GFNSEO'
              AND L.RPRATRM_OFFER_AMT > 0
              
       LEFT JOIN aidy_coa_total act 
           ON act.PIDM = RORSTAT_PIDM
           
       LEFT JOIN term_charges tc_smr
           ON tc_smr.PIDM = RORSTAT_PIDM 
              AND tc_smr.TERM = :SMR_TRM
              
       LEFT JOIN term_charges tc_fal
           ON tc_fal.PIDM = RORSTAT_PIDM 
              AND tc_fal.TERM = :FAL_TRM

       LEFT JOIN term_charges tc_spr
           ON tc_spr.PIDM = RORSTAT_PIDM 
              AND tc_spr.TERM = :SPR_TRM

       LEFT JOIN term_coa tc_smr_coa
           ON tc_smr_coa.PIDM = RORSTAT_PIDM 
              AND tc_smr_coa.TERM = :SMR_TRM

       LEFT JOIN term_coa tc_fal_coa
           ON tc_fal_coa.PIDM = RORSTAT_PIDM 
              AND tc_fal_coa.TERM = :FAL_TRM
              
       LEFT JOIN term_coa tc_spr_coa
           ON tc_spr_coa.PIDM = RORSTAT_PIDM 
              AND tc_spr_coa.TERM = :SPR_TRM
              
       LEFT JOIN aidy_awards aa 
           ON aa.PIDM = RORSTAT_PIDM
           
       LEFT JOIN term_hours th_smr
           ON th_smr.PIDM = RORSTAT_PIDM 
              AND th_smr.TERM = :SMR_TRM
              
       LEFT JOIN term_hours th_fal
           ON th_fal.PIDM = RORSTAT_PIDM 
              AND th_fal.TERM = :FAL_TRM
              
       LEFT JOIN term_hours th_spr
           ON th_spr.PIDM = RORSTAT_PIDM 
              AND th_spr.TERM = :SPR_TRM
              
       LEFT JOIN latest_sgbstdn sgb
           ON  sgb.PIDM = RORSTAT_PIDM
              
 WHERE     RORSTAT_AIDY_CODE = :AIDY
       AND RORSTAT_PCKG_COMP_DATE IS NOT NULL
       AND RORSTAT_APRD_CODE NOT LIKE 'CPM%'
       AND RCRAPP1_CURR_REC_IND = 'Y'
              AND NOT (    ROBUSDF_VALUE_201 IS NULL
                AND (SELECT SUM (SFRSTCR_CREDIT_HR)
                       FROM SFRSTCR
                      WHERE     SFRSTCR_PIDM = RORSTAT_PIDM
                            AND sfrstcr_term_code <= :SPR_TRM
                            AND SFRSTCR_RSTS_CODE IN ('RR','RE','RW','R2')) < 6)
