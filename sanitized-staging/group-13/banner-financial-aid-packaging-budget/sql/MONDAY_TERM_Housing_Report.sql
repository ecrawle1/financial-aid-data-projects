-- SANITIZED PUBLIC VERSION
-- Direct student/borrower identifiers and hard-coded student data have been removed from public output.
-- Literal student ID/SSN lists have been replaced with bind parameters where applicable.
-- Schema fields may remain internally where required for joins, filtering, or comparison logic.
-- Do not commit query results or exports containing student records.

WITH
    base_population
    AS
        (SELECT RORSTAT_PIDM                   AS PIDM,
                RORSTAT_AIDY_CODE              AS AIDY_CODE,
                RORSTAT_APRD_CODE              AS APRD,
                RORSTAT_PGRP_CODE              AS PGRP,
                RORSTAT_PCKG_COMP_DATE         AS PCKG_COMP_DATE,
                RORSTAT_PCKG_REQ_COMP_DATE     AS PCKG_REQ_COMP_DATE
           FROM RORSTAT
          WHERE     RORSTAT_AIDY_CODE = :AIDY
                AND RORSTAT_PCKG_COMP_DATE IS NOT NULL
                AND RORSTAT_APRD_CODE NOT LIKE 'CPM%'),
                
    current_fafsa
    AS
        (SELECT A.RCRAPP1_PIDM             AS PIDM,
                A.RCRAPP1_CURR_REC_IND     AS FAFSA_IND,
                B.RCRAPP2_MODEL_CDE        AS DEPENDENCY
           FROM RCRAPP1  A
                JOIN base_population BP
                    ON     BP.PIDM = A.RCRAPP1_PIDM
                       AND BP.AIDY_CODE = A.RCRAPP1_AIDY_CODE
                LEFT JOIN RCRAPP2 B
                    ON     B.RCRAPP2_PIDM = A.RCRAPP1_PIDM
                       AND B.RCRAPP2_AIDY_CODE = A.RCRAPP1_AIDY_CODE
                       AND B.RCRAPP2_INFC_CODE = A.RCRAPP1_INFC_CODE
                       AND B.RCRAPP2_SEQ_NO = A.RCRAPP1_SEQ_NO
          WHERE A.RCRAPP1_INFC_CODE = 'EDE' AND A.RCRAPP1_CURR_REC_IND = 'Y'),
          
    latest_sgbstdn
    AS
        (SELECT PIDM, STYP_CODE, LEVL_CODE
           FROM (SELECT S.SGBSTDN_PIDM                                      AS PIDM,
                        S.SGBSTDN_STYP_CODE                                 AS STYP_CODE,
                        S.SGBSTDN_LEVL_CODE                                 AS LEVL_CODE,
                        ROW_NUMBER ()
                            OVER (PARTITION BY S.SGBSTDN_PIDM
                                  ORDER BY S.SGBSTDN_TERM_CODE_EFF DESC)    AS RN
                   FROM SGBSTDN  S
                        JOIN base_population BP ON BP.PIDM = S.SGBSTDN_PIDM
                  WHERE S.SGBSTDN_TERM_CODE_EFF <= :SPR_TRM)
          WHERE RN = 1),
          
    term_charges_by_term
    AS
        (  SELECT T.TBRACCD_PIDM         AS PIDM,
                  T.TBRACCD_TERM_CODE    AS TERM_CODE,
                  SUM (
                      CASE
                          WHEN T.TBRACCD_DETAIL_CODE LIKE 'H%'
                          THEN
                              T.TBRACCD_AMOUNT
                          ELSE
                              0
                      END)               AS H_CHARGES,
                  SUM (
                      CASE
                          WHEN T.TBRACCD_DETAIL_CODE LIKE 'M%'
                          THEN
                              T.TBRACCD_AMOUNT
                          ELSE
                              0
                      END)               AS M_CHARGES
             FROM TBRACCD T JOIN base_population BP ON BP.PIDM = T.TBRACCD_PIDM
            WHERE T.TBRACCD_TERM_CODE IN ( :SMR_TRM, :FAL_TRM, :SPR_TRM)
         GROUP BY T.TBRACCD_PIDM, T.TBRACCD_TERM_CODE),
         
    term_charges
    AS
        (  SELECT PIDM,
                  MAX (CASE WHEN TERM_CODE = :SMR_TRM THEN H_CHARGES END)
                      AS SMR_H_CHARGES,
                  MAX (CASE WHEN TERM_CODE = :SMR_TRM THEN M_CHARGES END)
                      AS SMR_M_CHARGES,
                  MAX (CASE WHEN TERM_CODE = :FAL_TRM THEN H_CHARGES END)
                      AS FAL_H_CHARGES,
                  MAX (CASE WHEN TERM_CODE = :FAL_TRM THEN M_CHARGES END)
                      AS FAL_M_CHARGES,
                  MAX (CASE WHEN TERM_CODE = :SPR_TRM THEN H_CHARGES END)
                      AS SPR_H_CHARGES,
                  MAX (CASE WHEN TERM_CODE = :SPR_TRM THEN M_CHARGES END)
                      AS SPR_M_CHARGES
             FROM term_charges_by_term
         GROUP BY PIDM),
         
    term_coa_by_term
    AS
        (  SELECT R.RBRAPBC_PIDM      AS PIDM,
                  R.RBRAPBC_PERIOD    AS TERM_CODE,
                  SUM (
                      CASE
                          WHEN R.RBRAPBC_PBCP_CODE = 'R+B' THEN R.RBRAPBC_AMT
                          ELSE 0
                      END)            AS TOT_RB,
                  SUM (
                      CASE
                          WHEN R.RBRAPBC_PBCP_CODE = 'R+BF' THEN R.RBRAPBC_AMT
                          ELSE 0
                      END)            AS TOT_RBF
             FROM RBRAPBC R JOIN base_population BP ON BP.PIDM = R.RBRAPBC_PIDM
            WHERE     R.RBRAPBC_AIDY_CODE = :AIDY
                  AND R.RBRAPBC_PERIOD IN ( :SMR_TRM, :FAL_TRM, :SPR_TRM)
                  AND R.RBRAPBC_RUN_NAME = 'ACTUAL'
                  AND R.RBRAPBC_PBTP_CODE = 'COA'
         GROUP BY R.RBRAPBC_PIDM, R.RBRAPBC_PERIOD),
         
    term_coa
    AS
        (  SELECT PIDM,
                  MAX (CASE WHEN TERM_CODE = :SMR_TRM THEN TOT_RB END)
                      AS SMR_TOT_RB,
                  MAX (CASE WHEN TERM_CODE = :SMR_TRM THEN TOT_RBF END)
                      AS SMR_TOT_RBF,
                  MAX (CASE WHEN TERM_CODE = :FAL_TRM THEN TOT_RB END)
                      AS FAL_TOT_RB,
                  MAX (CASE WHEN TERM_CODE = :FAL_TRM THEN TOT_RBF END)
                      AS FAL_TOT_RBF,
                  MAX (CASE WHEN TERM_CODE = :SPR_TRM THEN TOT_RB END)
                      AS SPR_TOT_RB,
                  MAX (CASE WHEN TERM_CODE = :SPR_TRM THEN TOT_RBF END)
                      AS SPR_TOT_RBF
             FROM term_coa_by_term
         GROUP BY PIDM),
         
    time_status_ranked
    AS
        (SELECT S.SFRTHST_PIDM                                      AS PIDM,
                S.SFRTHST_TERM_CODE                                 AS TERM_CODE,
                S.SFRTHST_TMST_CODE                                 AS TMST_CODE,
                ROW_NUMBER ()
                    OVER (PARTITION BY S.SFRTHST_PIDM, S.SFRTHST_TERM_CODE
                          ORDER BY S.SFRTHST_ACTIVITY_DATE DESC)    AS RN
           FROM SFRTHST S JOIN base_population BP ON BP.PIDM = S.SFRTHST_PIDM
          WHERE S.SFRTHST_TERM_CODE IN ( :SMR_TRM, :FAL_TRM, :SPR_TRM)),
          
    latest_time_status
    AS
        (  SELECT PIDM,
                  MAX (CASE WHEN TERM_CODE = :SMR_TRM THEN TMST_CODE END)
                      AS SMR_TMST,
                  MAX (CASE WHEN TERM_CODE = :FAL_TRM THEN TMST_CODE END)
                      AS FAL_TMST,
                  MAX (CASE WHEN TERM_CODE = :SPR_TRM THEN TMST_CODE END)
                      AS SPR_TMST
             FROM time_status_ranked
            WHERE RN = 1
         GROUP BY PIDM),
         
    housing_response
    AS
        (  SELECT R.RPRINFO_PIDM                  AS PIDM,
                  MAX (R.RPRINFO_CREATE_DATE)     AS HOUSING_RESPONSE_DATE
             FROM RPRINFO R JOIN base_population BP ON BP.PIDM = R.RPRINFO_PIDM
            WHERE     R.RPRINFO_AIDY_CODE = :AIDY
                  AND R.RPRINFO_TYPE_CODE = 'Q'
                  AND R.RPRINFO_QUESTION_CODE = 'HOUSE'
         GROUP BY R.RPRINFO_PIDM),
         
    requirement_ranked
    AS
        (SELECT R.RRRAREQ_PIDM                                             AS PIDM,
                R.RRRAREQ_TREQ_CODE                                        AS TREQ_CODE,
                R.RRRAREQ_TRST_CODE                                        AS TRST_CODE,
                R.RRRAREQ_STAT_DATE                                        AS STAT_DATE,
                ROW_NUMBER ()
                    OVER (PARTITION BY R.RRRAREQ_PIDM, R.RRRAREQ_TREQ_CODE
                          ORDER BY R.RRRAREQ_STAT_DATE DESC NULLS LAST)    AS RN
           FROM RRRAREQ  R
                JOIN base_population BP
                    ON     BP.PIDM = R.RRRAREQ_PIDM
                       AND BP.AIDY_CODE = R.RRRAREQ_AIDY_CODE
          WHERE R.RRRAREQ_TREQ_CODE IN ('HOUSNG', 'ZQA')),
          
    requirements
    AS
        (  SELECT PIDM,
                  MAX (CASE WHEN TREQ_CODE = 'HOUSNG' THEN TREQ_CODE END)
                      AS HOUSING_TREQ,
                  MAX (CASE WHEN TREQ_CODE = 'HOUSNG' THEN TRST_CODE END)
                      AS HOUSING_STATUS,
                  MAX (CASE WHEN TREQ_CODE = 'HOUSNG' THEN STAT_DATE END)
                      AS HOUSING_STATUS_DATE,
                  MAX (CASE WHEN TREQ_CODE = 'ZQA' THEN TREQ_CODE END)
                      AS ZQA_TREQ,
                  MAX (CASE WHEN TREQ_CODE = 'ZQA' THEN TRST_CODE END)
                      AS ZQA_STATUS,
                  MAX (CASE WHEN TREQ_CODE = 'ZQA' THEN STAT_DATE END)
                      AS ZQA_STATUS_DATE
             FROM requirement_ranked
            WHERE RN = 1
         GROUP BY PIDM),
         
    registered_hours
    AS
        (  SELECT S.SFRSTCR_PIDM                AS PIDM,
                  SUM (S.SFRSTCR_CREDIT_HR)     AS TOTAL_REGISTERED_HOURS
           FROM SFRSTCR S JOIN base_population BP ON BP.PIDM = S.SFRSTCR_PIDM
            WHERE     S.SFRSTCR_TERM_CODE <= :SPR_TRM
                  AND S.SFRSTCR_RSTS_CODE IN ('RR','RE','RW','R2')
         GROUP BY S.SFRSTCR_PIDM),
         
         NEED_DATA 
    AS 
        ( SELECT  RNVAND0.RNVAND0_PIDM AS PIDM,
                  RNVAND0.RNVAND0_AIDY_CODE,
              NVL(RNVAND0.RNVAND0_BUDGET_AMOUNT, 0) AS COA_TOTAL,
              NVL(RNVAND0.RNVAND0_GROSS_NEED, 0) AS COA_REMAINING,
              NVL(RNVAND0.RNVAND0_UNMET_NEED, 0) AS UNMET_NEED
    FROM RNVAND0
   
    JOIN RCRAPP1
      ON RCRAPP1.RCRAPP1_PIDM = RNVAND0.RNVAND0_PIDM
     AND RCRAPP1.RCRAPP1_AIDY_CODE = RNVAND0.RNVAND0_AIDY_CODE
    WHERE RCRAPP1.RCRAPP1_AIDY_CODE = :AIDY
      AND RCRAPP1.RCRAPP1_INFC_CODE = 'EDE'
      AND RCRAPP1.RCRAPP1_CURR_REC_IND = 'Y'
       ),
       
    TERM_AWARDS 
    AS 
     ( SELECT RPRATRM.RPRATRM_PIDM AS PIDM,
     
     SUM(CASE WHEN RPRATRM.RPRATRM_TERM_CODE LIKE '%60' THEN NVL(RPRATRM.RPRATRM_OFFER_AMT, 0) ELSE NULL
            END) AS SMR_AID_OFFER,
     SUM(CASE WHEN RPRATRM.RPRATRM_TERM_CODE LIKE '%80' THEN NVL(RPRATRM.RPRATRM_OFFER_AMT, 0) ELSE NULL
            END) AS FAL_AID_OFFER,
     SUM(CASE WHEN RPRATRM.RPRATRM_TERM_CODE LIKE '%10' THEN NVL(RPRATRM.RPRATRM_OFFER_AMT, 0) ELSE NULL
            END) AS SPR_AID_OFFER

    FROM RPRATRM

    WHERE RPRATRM.RPRATRM_AIDY_CODE = :AIDY

    GROUP BY
        RPRATRM.RPRATRM_PIDM
    )
       
SELECT NULL AS STUDENT_ID,
       NULL AS STUDENT_FIRST_NAME,
       NULL AS STUDENT_LAST_NAME,
       CF.FAFSA_IND             AS FAFSA_IND,
       BP.APRD                  AS APRD,
       BP.PGRP                  AS PGRP,
       TO_CHAR (BP.PCKG_COMP_DATE, 'MM/DD/YYYY') AS PCKG_DATE,
       TO_CHAR (BP.PCKG_REQ_COMP_DATE, 'MM/DD/YYYY') AS PCKG_REQ_COMP_DATE,
       CF.DEPENDENCY            AS DEPENDENCY,
       SGB.STYP_CODE            AS STU_TYPE,
       SGB.LEVL_CODE            AS MAX_STU_LEVEL,
       TO_CHAR(nd.unmet_need, '$999,999,990.00') AS UNMET_NEED,
       TO_CHAR(nd.coa_total, '$999,999,990.00') AS COA_TOTAL,
       TO_CHAR(ta.SMR_AID_OFFER, '$999,999,990.00') AS SMR_AID_OFFERED,
       TO_CHAR(ta.FAL_AID_OFFER, '$999,999,990.00') AS FAL_AID_OFFERED,
       TO_CHAR(ta.SPR_AID_OFFER, '$999,999,990.00') AS SPR_AID_OFFERED,
       LTS.SMR_TMST             AS SMR_TMST,
       TO_CHAR (TC.SMR_H_CHARGES, '$999,999,990.00') AS SMR_H_CHARGES,
       TO_CHAR (TC.SMR_M_CHARGES, '$999,999,990.00') AS SMR_M_CHARGES,
       TO_CHAR (COA.SMR_TOT_RB, '$999,999,990.00') AS SMR_TOT_RB,
       TO_CHAR (COA.SMR_TOT_RBF, '$999,999,990.00') AS SMR_TOT_RBF,
       LTS.FAL_TMST             AS FAL_TMST,
       TO_CHAR (TC.FAL_H_CHARGES, '$999,999,990.00') AS FAL_H_CHARGES,
       TO_CHAR (TC.FAL_M_CHARGES, '$999,999,990.00') AS FAL_M_CHARGES,
       TO_CHAR (COA.FAL_TOT_RB, '$999,999,990.00') AS FAL_TOT_RB,
       TO_CHAR (COA.FAL_TOT_RBF, '$999,999,990.00') AS FAL_TOT_RBF,
       LTS.SPR_TMST            AS SPR_TMST,
       TO_CHAR (TC.SPR_H_CHARGES, '$999,999,990.00') AS SPR_H_CHARGES,
       TO_CHAR (TC.SPR_M_CHARGES, '$999,999,990.00') AS SPR_M_CHARGES,
       TO_CHAR (COA.SPR_TOT_RB, '$999,999,990.00') AS SPR_TOT_RB,
       TO_CHAR (COA.SPR_TOT_RBF, '$999,999,990.00') AS SPR_TOT_RBF,
       UDF.ROBUSDF_VALUE_202   AS ROBUSDF_VALUE_202,
       UDF.ROBUSDF_VALUE_203  AS ROBUSDF_VALUE_203,
       UDF.ROBUSDF_VALUE_204  AS ROBUSDF_VALUE_204,
       UDF.ROBUSDF_VALUE_205   AS ROBUSDF_VALUE_205,
       UDF.ROBUSDF_VALUE_206   AS ROBUSDF_VALUE_206,
       UDF.ROBUSDF_VALUE_207   AS ROBUSDF_VALUE_207,
       UDF.ROBUSDF_VALUE_208  AS ROBUSDF_VALUE_208,
       HR.HOUSING_RESPONSE_DATE AS HOUSING_RESPONSE_DATE,
       REQ.HOUSING_TREQ       AS HOUSING_TREQ,
       REQ.HOUSING_STATUS     AS HOUSING_STATUS,
       TO_CHAR (REQ.HOUSING_STATUS_DATE, 'MM/DD/YYYY') AS HOUSING_STATUS_DATE,
       REQ.ZQA_TREQ           AS ZQA_TREQ,
       REQ.ZQA_STATUS         AS ZQA_STATUS,
       REQ.ZQA_STATUS_DATE    AS ZQA_STATUS_DATE
       
  FROM base_population  BP 
       JOIN current_fafsa CF ON CF.PIDM = BP.PIDM
       LEFT JOIN SPRIDEN ID
           ON ID.SPRIDEN_PIDM = BP.PIDM AND ID.SPRIDEN_CHANGE_IND IS NULL
           
       LEFT JOIN latest_sgbstdn SGB ON SGB.PIDM = BP.PIDM
       
       LEFT JOIN term_charges TC ON TC.PIDM = BP.PIDM
       
       LEFT JOIN term_coa COA ON COA.PIDM = BP.PIDM
       
       LEFT JOIN latest_time_status LTS ON LTS.PIDM = BP.PIDM
       
       LEFT JOIN ROBUSDF UDF
           ON     UDF.ROBUSDF_PIDM = BP.PIDM
              AND UDF.ROBUSDF_AIDY_CODE = BP.AIDY_CODE
              
       LEFT JOIN housing_response HR ON HR.PIDM = BP.PIDM
       
       LEFT JOIN requirements REQ ON REQ.PIDM = BP.PIDM
       
       LEFT JOIN registered_hours RH ON RH.PIDM = BP.PIDM
       
       LEFT JOIN need_data nd ON nd.pidm = bp.pidm
       
       LEFT JOIN term_awards ta ON ta.pidm = bp.pidm
       
 WHERE    UDF.ROBUSDF_VALUE_201 IS NOT NULL
       OR NVL (RH.TOTAL_REGISTERED_HOURS, 0) >= 6;