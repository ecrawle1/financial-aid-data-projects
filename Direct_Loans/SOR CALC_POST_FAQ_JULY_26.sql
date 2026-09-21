/*
   UPDATE: Previous / Current / Future term handling for SOR hours

   PREVIOUS term: latest final-grade credit hours where SHRGRDE_ATTEMPTED_IND = 'Y'
   CURRENT term : actual FEDAID hours
   FUTURE term  : actual FEDAID hours when available; otherwise XES estimate

   Role examples:
     Fall run   -> Summer PREVIOUS, Fall CURRENT, Spring FUTURE
     Spring run -> Summer PREVIOUS, Fall PREVIOUS, Spring CURRENT

   The term roles are derived automatically from :TERM, :SMR_TERM,
   :FAL_TERM, and :SPR_TERM. No manual comment/uncomment switch is needed.
*/

    --Base population all students with sub or unsub loans
    WITH 
    LOAN_POP AS (
        SELECT DISTINCT
            RPRATRM_PIDM AS PIDM,
            RPRATRM_AIDY_CODE AS AIDY_CODE
        FROM RPRATRM
        WHERE RPRATRM_AIDY_CODE = :AIDY
          AND RPRATRM_TERM_CODE = :TERM
          AND (
                 RPRATRM_FUND_CODE LIKE 'LFNS%'
              OR RPRATRM_FUND_CODE LIKE 'LFUU%'
          )
          AND (
                 NVL(RPRATRM_OFFER_AMT, 0) <> 0
              OR NVL(RPRATRM_ACCEPT_AMT, 0) <> 0
              OR NVL(RPRATRM_MEMO_AMT, 0) <> 0
              OR NVL(RPRATRM_PAID_AMT, 0) <> 0
          )
    ),
    
    --Aid period and Expected enrollment to be used to calculate loan eligibility and loan period factor, tracking and packaging groups for content
    STUDENT_REC AS (
        SELECT
            LP.PIDM,
            LP.AIDY_CODE,
            RORSTAT.RORSTAT_PCKG_COMP_DATE AS PCKG_COMP_DATE,
            RORSTAT.RORSTAT_PGRP_CODE AS PACKAGING_GROUP,
            RORSTAT.RORSTAT_TGRP_CODE AS TRACKING_GROUP,
            RORSTAT.RORSTAT_APRD_CODE AS AID_PERIOD,
            RORSTAT.RORSTAT_XES AS YEAR_EXPECTED_ENROLLMENT,

            CASE
                WHEN RORSTAT.RORSTAT_APRD_CODE = 'SMFLSP' THEN 3
                WHEN RORSTAT.RORSTAT_APRD_CODE IN ('SMRFAL', 'SMRSPR', 'FA/SPR') THEN 2
                WHEN RORSTAT.RORSTAT_APRD_CODE IN ('SUMMER', 'FALL', 'SPRING') THEN 1
                ELSE NULL
            END AS TERMS_IN_PERIOD,

            CASE
                WHEN RORSTAT.RORSTAT_APRD_CODE IN ('SUMMER', 'FALL', 'SPRING') THEN 'SINGLE_TERM'
                WHEN RORSTAT.RORSTAT_APRD_CODE IN ('SMRFAL', 'SMRSPR', 'FA/SPR', 'SMFLSP') THEN 'MULTI_TERM'
                ELSE 'UNKNOWN'
            END AS LOAN_PERIOD_TYPE

        FROM LOAN_POP LP
        JOIN RORSTAT
          ON RORSTAT.RORSTAT_PIDM = LP.PIDM
         AND RORSTAT.RORSTAT_AIDY_CODE = LP.AIDY_CODE
    ),
     -- added as part of the student level data to make sure the current record is selected
    MAX_SGBSTDN AS (
        SELECT
            SGBSTDN_PIDM,
            MAX(SGBSTDN_TERM_CODE_EFF) AS MAX_TERM_CODE_EFF
        FROM SGBSTDN
        WHERE SGBSTDN_TERM_CODE_EFF <= :TERM
          AND SGBSTDN_STST_CODE = 'AS'
        GROUP BY SGBSTDN_PIDM
    ),
    --provides level for classifying as UG/GR/PR for loan limits tables, other content included for end user
    STUDENT_LEVEL AS (
        SELECT
            SGBSTDN.SGBSTDN_PIDM,
            SGBSTDN.SGBSTDN_LEVL_CODE,
            SGBSTDN.SGBSTDN_STYP_CODE,
            SGBSTDN.SGBSTDN_PROGRAM_1,
            SGBSTDN.SGBSTDN_TERM_CODE_EFF AS PROGRAM_TERM
        FROM SGBSTDN
        JOIN MAX_SGBSTDN
          ON MAX_SGBSTDN.SGBSTDN_PIDM = SGBSTDN.SGBSTDN_PIDM
         AND MAX_SGBSTDN.MAX_TERM_CODE_EFF = SGBSTDN.SGBSTDN_TERM_CODE_EFF
    ),
    -- contributes SAI for loan eligibility calc and dependency status and grade level for grade bucket
    STUDENT_LIMIT_DATA AS (
        SELECT
            RCRAPP2.RCRAPP2_PIDM,
            RCRAPP1.RCRAPP1_AIDY_CODE,
            RCRAPP2.RCRAPP2_PELL_PGI AS SAI,
            RCRAPP1.RCRAPP1_YR_IN_COLL AS GRADE_LEVEL,
            RCRAPP2.RCRAPP2_MODEL_CDE AS DEPENDENCY_STATUS
            
        FROM RCRAPP1
        
        JOIN RCRAPP2
          ON RCRAPP2.RCRAPP2_PIDM = RCRAPP1.RCRAPP1_PIDM
         AND RCRAPP2.RCRAPP2_AIDY_CODE = RCRAPP1.RCRAPP1_AIDY_CODE
         AND RCRAPP2.RCRAPP2_INFC_CODE = RCRAPP1.RCRAPP1_INFC_CODE
         AND RCRAPP2.RCRAPP2_SEQ_NO = RCRAPP1.RCRAPP1_SEQ_NO
         
        WHERE RCRAPP1.RCRAPP1_AIDY_CODE = :AIDY
          AND RCRAPP1.RCRAPP1_INFC_CODE = 'EDE'
          AND RCRAPP1.RCRAPP1_CURR_REC_IND = 'Y'
    ),
    -- FED AID hours used to confirm students registered hours are approved Course Program of Study Hours
    FEDAID_HOURS AS (
        SELECT/*+ MATERIALIZE */
            SR.PIDM,
            SR.AIDY_CODE,
            ROKMISC_RULES.F_CALC_RULE_HRS_NO_ROTSREG(:AIDY, SR.PIDM, :SMR_TERM, 'FEDAID') AS SMR_FEDAID_HOURS,
            ROKMISC_RULES.F_CALC_RULE_HRS_NO_ROTSREG(:AIDY, SR.PIDM, :FAL_TERM, 'FEDAID') AS FAL_FEDAID_HOURS,
            ROKMISC_RULES.F_CALC_RULE_HRS_NO_ROTSREG(:AIDY, SR.PIDM, :SPR_TERM, 'FEDAID') AS SPR_FEDAID_HOURS
        FROM STUDENT_REC SR
    ),

    /*
       ============================================================
       SOR PRIOR-TERM HOURS
       ============================================================

       When a term is PREVIOUS at the time the report is run, use
       the student's latest final academic-history record for that term.

       Explicit Kent prior-term SOR grade rule:
           COUNT: A, A-, B+, B, B-, C+, C, C-, D+, D, F, S
                  when Banner also identifies the grade as attempted.

           DO NOT COUNT: NF, SF, W, WD, WF, WP, NG, ND.

       F is intentionally retained even though PASSED_IND = 'N'.
       The calculation therefore does not rely on PASSED_IND to
       decide prior-term SOR hours.
    */
    LATEST_SOR_GRADE AS (
        SELECT /*+ MATERIALIZE */
            G.SHRTCKG_PIDM AS PIDM,
            G.SHRTCKG_TERM_CODE AS TERM_CODE,
            G.SHRTCKG_TCKN_SEQ_NO AS TCKN_SEQ_NO,
            G.SHRTCKG_GRDE_CODE_FINAL AS FINAL_GRADE,
            NVL(G.SHRTCKG_CREDIT_HOURS, 0) AS CREDIT_HOURS,
            ROW_NUMBER() OVER (
                PARTITION BY
                    G.SHRTCKG_PIDM,
                    G.SHRTCKG_TERM_CODE,
                    G.SHRTCKG_TCKN_SEQ_NO
                ORDER BY G.SHRTCKG_SEQ_NO DESC
            ) AS RN
        FROM SHRTCKG G
        JOIN STUDENT_REC SR
          ON SR.PIDM = G.SHRTCKG_PIDM
        WHERE G.SHRTCKG_TERM_CODE IN (:SMR_TERM, :FAL_TERM, :SPR_TERM)
    ),

    /*
       Oracle does not allow the effective-dated SHRGRDE scalar subquery
       inside the LEFT JOIN predicate (ORA-01799). Pre-rank the grade
       definitions by aid-year term instead, then join to RN = 1.
    */
    SOR_GRADE_TERMS AS (
        SELECT :SMR_TERM AS TERM_CODE FROM DUAL
        UNION ALL
        SELECT :FAL_TERM AS TERM_CODE FROM DUAL
        UNION ALL
        SELECT :SPR_TERM AS TERM_CODE FROM DUAL
    ),

    SOR_GRADE_DEFS AS (
        SELECT
            T.TERM_CODE,
            GR.SHRGRDE_CODE,
            GR.SHRGRDE_LEVL_CODE,
            GR.SHRGRDE_ATTEMPTED_IND,
            ROW_NUMBER() OVER (
                PARTITION BY
                    T.TERM_CODE,
                    GR.SHRGRDE_CODE,
                    GR.SHRGRDE_LEVL_CODE
                ORDER BY GR.SHRGRDE_TERM_CODE_EFFECTIVE DESC
            ) AS RN
        FROM SOR_GRADE_TERMS T
        JOIN SHRGRDE GR
          ON GR.SHRGRDE_TERM_CODE_EFFECTIVE <= T.TERM_CODE
        WHERE GR.SHRGRDE_LEVL_CODE IN ('UG', 'GR', 'PR')
    ),

    /* Apply the explicit prior-term grade rule once at the course level. */
    SOR_PRIOR_TERM_COURSE_HOURS AS (
        SELECT
            LG.PIDM,
            LG.TERM_CODE,

            CASE
                /* Standard completed grades, including an earned F. */
                WHEN GR.SHRGRDE_ATTEMPTED_IND = 'Y'
                 AND GR.SHRGRDE_CODE IN (
                        'A','A-',
                        'B+','B','B-',
                        'C+','C','C-',
                        'D+','D',
                        'F',
                        'S'
                     )
                    THEN NVL(LG.CREDIT_HOURS, 0)

                /* Do not count nonattendance / stopped attendance / withdrawals. */
                WHEN GR.SHRGRDE_CODE IN (
                        'NF','SF',
                        'W','WD','WF','WP'
                     )
                    THEN 0

                /* No-grade / not-determined values are not prior-term SOR hours. */
                WHEN GR.SHRGRDE_CODE IN ('NG','ND')
                    THEN 0

                ELSE 0
            END AS SOR_PRIOR_TERM_HOURS

        FROM LATEST_SOR_GRADE LG

        LEFT JOIN STUDENT_LEVEL SL
          ON SL.SGBSTDN_PIDM = LG.PIDM

        LEFT JOIN SOR_GRADE_DEFS GR
          ON GR.TERM_CODE = LG.TERM_CODE
         AND GR.SHRGRDE_CODE = LG.FINAL_GRADE
         AND GR.SHRGRDE_LEVL_CODE = SL.SGBSTDN_LEVL_CODE
         AND GR.RN = 1

        WHERE LG.RN = 1
    ),

    SOR_PRIOR_TERM_HOURS AS (
        SELECT
            PIDM,

            SUM(
                CASE
                    WHEN TERM_CODE = :SMR_TERM
                        THEN SOR_PRIOR_TERM_HOURS
                    ELSE 0
                END
            ) AS SMR_SOR_PRIOR_HOURS,

            SUM(
                CASE
                    WHEN TERM_CODE = :FAL_TERM
                        THEN SOR_PRIOR_TERM_HOURS
                    ELSE 0
                END
            ) AS FAL_SOR_PRIOR_HOURS,

            SUM(
                CASE
                    WHEN TERM_CODE = :SPR_TERM
                        THEN SOR_PRIOR_TERM_HOURS
                    ELSE 0
                END
            ) AS SPR_SOR_PRIOR_HOURS

        FROM SOR_PRIOR_TERM_COURSE_HOURS
        GROUP BY PIDM
    ),
    --Included for comparison only
    REGISTERED_HOURS AS (
        SELECT
            SFRSTCR.SFRSTCR_PIDM,
            SUM(CASE WHEN SFRSTCR.SFRSTCR_TERM_CODE = :SMR_TERM THEN NVL(SFRSTCR.SFRSTCR_BILL_HR, NVL(SFRSTCR.SFRSTCR_CREDIT_HR, 0)) ELSE 0 END) AS SMR_REGISTERED_HOURS,
            SUM(CASE WHEN SFRSTCR.SFRSTCR_TERM_CODE = :FAL_TERM THEN NVL(SFRSTCR.SFRSTCR_BILL_HR, NVL(SFRSTCR.SFRSTCR_CREDIT_HR, 0)) ELSE 0 END) AS FAL_REGISTERED_HOURS,
            SUM(CASE WHEN SFRSTCR.SFRSTCR_TERM_CODE = :SPR_TERM THEN NVL(SFRSTCR.SFRSTCR_BILL_HR, NVL(SFRSTCR.SFRSTCR_CREDIT_HR, 0)) ELSE 0 END) AS SPR_REGISTERED_HOURS,
            SUM(CASE WHEN SFRSTCR.SFRSTCR_TERM_CODE = :TERM THEN NVL(SFRSTCR.SFRSTCR_BILL_HR, NVL(SFRSTCR.SFRSTCR_CREDIT_HR, 0)) ELSE 0 END) AS CURR_REGISTERED_HOURS
            
        FROM SFRSTCR
        
        JOIN STUDENT_REC SR
          ON SR.PIDM = SFRSTCR.SFRSTCR_PIDM
          
        WHERE SFRSTCR.SFRSTCR_TERM_CODE IN (:SMR_TERM, :FAL_TERM, :SPR_TERM)
          AND SFRSTCR.SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')
          AND SFRSTCR.SFRSTCR_GMOD_CODE NOT IN ('SF', 'NF')
          AND SFRSTCR.SFRSTCR_LEVL_CODE IN ('UG', 'GR', 'PR')
        GROUP BY SFRSTCR.SFRSTCR_PIDM
    ),
    --CTE to include COA for sub/unsub calculated amount
    NEED_DATA AS (
        SELECT
            RNVAND0.RNVAND0_PIDM AS PIDM,
            RNVAND0.RNVAND0_AIDY_CODE AS AIDY_CODE,
            NVL(RNVAND0.RNVAND0_BUDGET_AMOUNT, 0) AS COA_TOTAL,
            NVL(RNVAND0.RNVAND0_GROSS_NEED, 0) AS COA_REMAINING,
            NVL(RNVAND0.RNVAND0_UNMET_NEED, 0) AS UNMET_NEED,
            NVL(RNVAND0_RESOURCE_AMOUNT, 0) AS OFA_RESOURCE 
        FROM RNVAND0
        JOIN STUDENT_REC SR
         ON SR.PIDM = RNVAND0.RNVAND0_PIDM
         AND SR.AIDY_CODE = RNVAND0.RNVAND0_AIDY_CODE
        JOIN RCRAPP1
          ON RCRAPP1.RCRAPP1_PIDM = RNVAND0.RNVAND0_PIDM
         AND RCRAPP1.RCRAPP1_AIDY_CODE = RNVAND0.RNVAND0_AIDY_CODE
        WHERE RCRAPP1.RCRAPP1_AIDY_CODE = :AIDY
          AND RCRAPP1.RCRAPP1_INFC_CODE = 'EDE'
          AND RCRAPP1.RCRAPP1_CURR_REC_IND = 'Y'
    ),
    --used to include any disbursed/paid sub/unsub loans as well as all other aid and include plus loans
    ANNUAL_AWARDS AS (
        SELECT
            RPRAWRD.RPRAWRD_PIDM AS PIDM,
            RPRAWRD.RPRAWRD_AIDY_CODE AS AIDY_CODE,

            /* Direct Subsidized only */
            SUM(
                CASE
                    WHEN RPRAWRD.RPRAWRD_FUND_CODE LIKE 'LFNS%'
                    THEN NVL(RPRAWRD.RPRAWRD_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS AY_SUB_OFFER,

            SUM(
                CASE
                    WHEN RPRAWRD.RPRAWRD_FUND_CODE LIKE 'LFNS%'
                    THEN NVL(RPRAWRD.RPRAWRD_PAID_AMT, 0)
                    ELSE 0
                END
            ) AS AY_SUB_PAID,

            /* Direct Unsubsidized only */
            SUM(
                CASE
                    WHEN RPRAWRD.RPRAWRD_FUND_CODE LIKE 'LFUU%'
                    THEN NVL(RPRAWRD.RPRAWRD_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS AY_UNSUB_OFFER,

            SUM(
                CASE
                    WHEN RPRAWRD.RPRAWRD_FUND_CODE LIKE 'LFUU%'
                    THEN NVL(RPRAWRD.RPRAWRD_PAID_AMT, 0)
                    ELSE 0
                END
            ) AS AY_UNSUB_PAID,

            /*
               ============================================================
               ALL OTHER AID
               ============================================================

               Broad pool of all other offered aid.

               Exclude only the Direct Subsidized and Direct Unsubsidized
               loans being recalculated by this report.

               This amount is used for the TOTAL Direct Loan COA cap.

               For the Subsidized need calculation, qualifying amounts
               used to replace SAI will be removed later.
            */
            SUM(
                CASE
                    WHEN RPRAWRD.RPRAWRD_FUND_CODE NOT LIKE 'LFNS%'
                     AND RPRAWRD.RPRAWRD_FUND_CODE NOT LIKE 'LFUU%'
                    THEN NVL(RPRAWRD.RPRAWRD_OFFER_AMT, 0)
                    ELSE 0
                END
            )
            + NVL(MAX(OFA_RESOURCE), 0)
                AS ALL_OTHER_AY_AID,
            
            SUM(
                CASE
                    WHEN RPRAWRD.RPRAWRD_FUND_CODE NOT LIKE 'LFNS%'
                     AND RPRAWRD.RPRAWRD_FUND_CODE NOT LIKE 'LFUU%'
                     AND RPRAWRD.RPRAWRD_FUND_CODE NOT LIKE '_FN%'
                     AND RPRAWRD.RPRAWRD_FUND_CODE NOT LIKE '_FB%'
                     AND RPRAWRD.RPRAWRD_FUND_CODE NOT LIKE '_SN%'
                     AND RPRAWRD.RPRAWRD_FUND_CODE NOT LIKE '_SB%'
                     AND RPRAWRD.RPRAWRD_FUND_CODE NOT LIKE 'JFNWA%'
                    THEN NVL(RPRAWRD.RPRAWRD_OFFER_AMT, 0)
                    ELSE 0
                END
            )
                AS MERIT_INSTITUTIONAL_AY_AID,
                

            /*
               ============================================================
               KSU NEED-BASED AID - INFORMATIONAL
               ============================================================

               Position 2:
                  F = Federal
                  S = State

               Position 3:
                  N = Need
                  B = Need + Merit

                'JFNWA%' = Federal Work Study.

               LFNS% is excluded because it is the Subsidized Loan
               being recalculated.
            */
            SUM(
                CASE
                    WHEN (
                            RPRAWRD.RPRAWRD_FUND_CODE LIKE '_FN%'
                         OR RPRAWRD.RPRAWRD_FUND_CODE LIKE '_FB%'
                         OR RPRAWRD.RPRAWRD_FUND_CODE LIKE '_SN%'
                         OR RPRAWRD.RPRAWRD_FUND_CODE LIKE '_SB%'
                         OR RPRAWRD.RPRAWRD_FUND_CODE LIKE 'JFNWA%'
                         )
                     AND RPRAWRD.RPRAWRD_FUND_CODE NOT LIKE 'LFNS%'
                    THEN NVL(RPRAWRD.RPRAWRD_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS NEED_BASED_AY_AID,

            /*
               Federal Work Study - shown separately for review.
            */
            SUM(
                CASE
                    WHEN RPRAWRD.RPRAWRD_FUND_CODE LIKE 'JFNWA%'
                    THEN NVL(RPRAWRD.RPRAWRD_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS FWS_OFFERED,

            /*
               TEACH Grant.

               Current known KSU TEACH fund codes:
                  GFUTGG
                  GFUTG1
            */
            SUM(
                CASE
                    WHEN RPRAWRD.RPRAWRD_FUND_CODE
                         IN ('GFUTGG', 'GFUTG1')
                    THEN NVL(RPRAWRD.RPRAWRD_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS TEACH_OFFERED,

            /*
               Private / alternative education loans.

               Current KSU identifier = LE%
            */
            SUM(
                CASE
                    WHEN RPRAWRD.RPRAWRD_FUND_CODE LIKE 'LE%'
                    THEN NVL(RPRAWRD.RPRAWRD_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS PRIVATE_LOAN_OFFERED,

            /*
               PLUS - already identified by the report.
            */
            SUM(
                CASE
                    WHEN RPRAWRD.RPRAWRD_FUND_CODE LIKE 'LFUG%'
                      OR RPRAWRD.RPRAWRD_FUND_CODE LIKE 'LFUP%'
                    THEN NVL(RPRAWRD.RPRAWRD_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS PLUS_OFFERED

        FROM RPRAWRD

        JOIN STUDENT_REC SR
          ON SR.PIDM = RPRAWRD.RPRAWRD_PIDM
         AND SR.AIDY_CODE = RPRAWRD.RPRAWRD_AIDY_CODE

        LEFT JOIN NEED_DATA ND
          ON  ND.PIDM = RPRAWRD.RPRAWRD_PIDM
         AND  ND.AIDY_CODE = RPRAWRD.RPRAWRD_AIDY_CODE

        WHERE RPRAWRD.RPRAWRD_AIDY_CODE = :AIDY

        GROUP BY
            RPRAWRD.RPRAWRD_PIDM,
            RPRAWRD.RPRAWRD_AIDY_CODE
    ),

    TERM_AWARDS AS (
        SELECT
            RPRATRM.RPRATRM_PIDM AS PIDM,
            RPRATRM.RPRATRM_AIDY_CODE AS AIDY_CODE,
            RPRATRM.RPRATRM_TERM_CODE AS TERM_CODE,

            SUM(
                CASE
                    WHEN RPRATRM.RPRATRM_FUND_CODE LIKE 'LFNS%'
                    THEN NVL(RPRATRM.RPRATRM_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS TERM_SUB_OFFER,

            SUM(
                CASE
                    WHEN RPRATRM.RPRATRM_FUND_CODE LIKE 'LFNS%'
                    THEN NVL(RPRATRM.RPRATRM_PAID_AMT, 0)
                    ELSE 0
                END
            ) AS TERM_SUB_PAID,

            SUM(
                CASE
                    WHEN RPRATRM.RPRATRM_FUND_CODE LIKE 'LFUU%'
                    THEN NVL(RPRATRM.RPRATRM_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS TERM_UNSUB_OFFER,

            SUM(
                CASE
                    WHEN RPRATRM.RPRATRM_FUND_CODE LIKE 'LFUU%'
                    THEN NVL(RPRATRM.RPRATRM_PAID_AMT, 0)
                    ELSE 0
                END
            ) AS TERM_UNSUB_PAID,

            /*
               This total now represents only the student Direct Loans
               being evaluated by this report.
            */
            SUM(
                CASE
                    WHEN RPRATRM.RPRATRM_FUND_CODE LIKE 'LFNS%'
                      OR RPRATRM.RPRATRM_FUND_CODE LIKE 'LFUU%'
                    THEN NVL(RPRATRM.RPRATRM_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS TERM_TOTAL_OFFER,

            SUM(
                CASE
                    WHEN RPRATRM_FUND_CODE = 'GFNPEL'
                    THEN NVL(RPRATRM_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS TERM_PELL_OFFER,

            SUM(
                CASE
                    WHEN RPRATRM_FUND_CODE = 'GFNPEL'
                    THEN NVL(RPRATRM_PAID_AMT, 0)
                    ELSE 0
                END
            ) AS TERM_PELL_PAID,
            
            
            SUM(
                CASE
                    WHEN RPRATRM_FUND_CODE NOT LIKE 'LFNS%'
                     AND RPRATRM_FUND_CODE NOT LIKE 'LFUU%'
                    THEN NVL(RPRATRM_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS ALL_OTHER_TERM_AID,

            SUM(
                CASE
                    WHEN RPRATRM_FUND_CODE LIKE 'LFUG%'
                      OR RPRATRM_FUND_CODE LIKE 'LFUP%'
                    THEN NVL(RPRATRM_OFFER_AMT, 0)
                    ELSE 0
                END
            ) AS TERM_PLUS_OFFERED

        FROM RPRATRM

        WHERE RPRATRM.RPRATRM_AIDY_CODE = :AIDY
          AND RPRATRM.RPRATRM_TERM_CODE = :TERM

        GROUP BY
            RPRATRM.RPRATRM_PIDM,
            RPRATRM.RPRATRM_AIDY_CODE,
            RPRATRM.RPRATRM_TERM_CODE
    ),
    
    SUMMER_LOAN_HISTORY AS (
            SELECT
                R.RPRATRM_PIDM      AS PIDM,
                R.RPRATRM_AIDY_CODE AS AIDY_CODE,

                SUM(
                    CASE
                        WHEN R.RPRATRM_FUND_CODE LIKE 'LFNS%'
                        THEN NVL(R.RPRATRM_PAID_AMT, 0)
                        ELSE 0
                    END
                ) AS SMR_SUB_PAID,

                SUM(
                    CASE
                        WHEN R.RPRATRM_FUND_CODE LIKE 'LFUU%'
                        THEN NVL(R.RPRATRM_PAID_AMT, 0)
                        ELSE 0
                    END
                ) AS SMR_UNSUB_PAID

            FROM RPRATRM R

            JOIN STUDENT_REC SR
              ON SR.PIDM = R.RPRATRM_PIDM
             AND SR.AIDY_CODE = R.RPRATRM_AIDY_CODE

            WHERE R.RPRATRM_AIDY_CODE = :AIDY
              AND R.RPRATRM_TERM_CODE = :SMR_TERM
              AND (
                     R.RPRATRM_FUND_CODE LIKE 'LFNS%'
                  OR R.RPRATRM_FUND_CODE LIKE 'LFUU%'
              )

            GROUP BY
                R.RPRATRM_PIDM,
                R.RPRATRM_AIDY_CODE
        ),

    ANNUAL_LIMITS AS (
          --Undergraduate limits remain unchanged.        
        /* Dependent undergraduate */
            SELECT
        'UG' AS CAREER,
        'DEPENDENT' AS DEPENDENCY_BUCKET,
        '1' AS GRADE_BUCKET,
        'ALL' AS LIMIT_RULE,
        5500 AS ANNUAL_TOTAL_LIMIT,
        3500 AS ANNUAL_SUB_LIMIT
        FROM DUAL
        
        UNION ALL SELECT 'UG', 'DEPENDENT', '2', 'ALL', 5500, 3500 FROM DUAL
        UNION ALL SELECT 'UG', 'DEPENDENT', '3', 'ALL', 6500, 4500 FROM DUAL
        UNION ALL SELECT 'UG', 'DEPENDENT', '4', 'ALL', 7500, 5500 FROM DUAL
        UNION ALL SELECT 'UG', 'DEPENDENT', '5', 'ALL', 7500, 5500 FROM DUAL
        UNION ALL SELECT 'UG', 'DEPENDENT', '6', 'ALL', 7500, 5500 FROM DUAL

        /* Independent undergraduate */
        UNION ALL SELECT 'UG', 'INDEPENDENT', '1', 'ALL',  9500, 3500 FROM DUAL
        UNION ALL SELECT 'UG', 'INDEPENDENT', '2', 'ALL',  9500, 3500 FROM DUAL
        UNION ALL SELECT 'UG', 'INDEPENDENT', '3', 'ALL', 10500, 4500 FROM DUAL
        UNION ALL SELECT 'UG', 'INDEPENDENT', '4', 'ALL', 12500, 5500 FROM DUAL
        UNION ALL SELECT 'UG', 'INDEPENDENT', '5', 'ALL', 12500, 5500 FROM DUAL
        UNION ALL SELECT 'UG', 'INDEPENDENT', '6', 'ALL', 12500, 5500 FROM DUAL

        /*
           NEW limits for borrowers subject to the
           July 1, 2026 rules.
        */
        UNION ALL SELECT 'GR', 'ANY', 'ANY', 'NEW',    20500, 0 FROM DUAL
        UNION ALL SELECT 'PR', 'ANY', 'ANY', 'NEW',    50000, 0 FROM DUAL

        /*
           LEGACY / interim-exception borrowers retain
           pre-July 1, 2026 rules.

           Standard GR/PR Direct Unsubsidized annual limit = 20,500.

           See note below concerning special legacy
           health-profession increased Unsubsidized limits.
        */
        UNION ALL SELECT 'GR', 'ANY', 'ANY', 'LEGACY', 20500, 0 FROM DUAL
        UNION ALL SELECT 'PR', 'ANY', 'ANY', 'LEGACY', 20500, 0 FROM DUAL
    ),

   AGG_LIMITS AS (
            /*
               Undergraduate aggregate limits remain unchanged.
            */
            SELECT
                'UG' AS CAREER,
                'DEPENDENT' AS DEPENDENCY_BUCKET,
                'ANY' AS AGG_BUCKET,
                'ALL' AS LIMIT_RULE,
                31000 AS AGG_TOTAL_LIMIT,
                23000 AS AGG_SUB_LIMIT
            FROM DUAL

            UNION ALL
            SELECT
                'UG',
                'INDEPENDENT',
                'ANY',
                'ALL',
                57500,
                23000
            FROM DUAL

            /*
               LEGACY / interim exception:
               retain the standard pre-7/1/2026
               graduate/professional combined aggregate.
            */
            UNION ALL
            SELECT
                'GR',
                'ANY',
                'ANY',
                'LEGACY',
                138500,
                65500
            FROM DUAL

            UNION ALL
            SELECT
                'PR',
                'ANY',
                'ANY',
                'LEGACY',
                138500,
                65500
            FROM DUAL
            
        /*
           2026-27 graduate/professional loan-level code
           from RCRAPP1_YR_IN_COLL:

           A = Graduate / never Professional
           B = Graduate / former Professional
           C = Professional / never Graduate
           D = Professional / former Graduate
           E = Graduate + Professional - majority Graduate
           F = Professional + Graduate - majority Professional
        */

        /*
           NEW GRADUATE LIMITS

           A = Graduate / never Professional
               -> $100,000

           B = Graduate / former Professional
           E = Graduate + Professional, majority Graduate
               -> $200,000
        */
        UNION ALL
        SELECT 'GR', 'ANY', 'A', 'NEW', 100000, 0 FROM DUAL

        UNION ALL
        SELECT 'GR', 'ANY', 'B', 'NEW', 200000, 0 FROM DUAL

        UNION ALL
        SELECT 'GR', 'ANY', 'E', 'NEW', 200000, 0 FROM DUAL


        /*
           NEW PROFESSIONAL LIMITS

           C = Professional / never Graduate
           D = Professional / former Graduate
           F = Professional + Graduate, majority Professional
               -> $200,000
        */
        UNION ALL
        SELECT 'PR', 'ANY', 'C', 'NEW', 200000, 0 FROM DUAL

        UNION ALL
        SELECT 'PR', 'ANY', 'D', 'NEW', 200000, 0 FROM DUAL

        UNION ALL
        SELECT 'PR', 'ANY', 'F', 'NEW', 200000, 0 FROM DUAL
        ),

    LIFETIME_LOANS AS (
        SELECT
            X.RCRLDS4_PIDM AS PIDM,

            /*
               =========================================================
               UNDERGRADUATE AGGREGATE USAGE

               Use the new UG-specific NSLDS fields when they contain
               actual amounts. Until those fields begin populating,
               fall back to the existing overall NSLDS aggregate fields.
               =========================================================
            */

            CASE
                WHEN NVL(X.RCRLDS4_AGT_UG_COMB_TOTAL, 0)
                   + NVL(X.RCRLDS4_AGT_UG_UNAL_CONS_TOTAL, 0) <> 0

                    THEN NVL(X.RCRLDS4_AGT_UG_COMB_TOTAL, 0)
                       + NVL(X.RCRLDS4_AGT_UG_UNAL_CONS_TOTAL, 0)

                ELSE NVL(X.RCRLDS4_AGT_COMB_TOTAL, 0)
            END AS UG_COMBINED_USED,

            COALESCE(
                NULLIF(X.RCRLDS4_AGT_UG_SUB_TOTAL, 0),
                X.RCRLDS4_AGT_SUB_TOTAL,
                0
            ) AS UG_SUB_USED,

            COALESCE(
                NULLIF(X.RCRLDS4_AGT_UG_UNSUB_TOTAL, 0),
                X.RCRLDS4_AGT_UNSUB_TOTAL,
                0
            ) AS UG_UNSUB_USED,

            /*
               =========================================================
               PRE-7/1/2026 GRADUATE/PROFESSIONAL AGGREGATE USAGE

               Use the new level-specific breakdown once actual values
               exist. Until then, fall back to the existing overall
               NSLDS aggregate totals.
               =========================================================
            */

            CASE
                WHEN NVL(X.RCRLDS4_AGT_UG_COMB_TOTAL, 0)
                   + NVL(X.RCRLDS4_AGT_GR_COMB_TOTAL, 0)
                   + NVL(X.RCRLDS4_AGT_UG_UNAL_CONS_TOTAL, 0)
                   + NVL(X.RCRLDS4_AGT_GR_UNAL_CONS_TOTAL, 0) <> 0

                    THEN NVL(X.RCRLDS4_AGT_UG_COMB_TOTAL, 0)
                       + NVL(X.RCRLDS4_AGT_UG_UNAL_CONS_TOTAL, 0)
                       + NVL(X.RCRLDS4_AGT_GR_COMB_TOTAL, 0)
                       + NVL(X.RCRLDS4_AGT_GR_UNAL_CONS_TOTAL, 0)

                ELSE NVL(X.RCRLDS4_AGT_COMB_TOTAL, 0)
            END AS PRE_2026_COMBINED_USED,

            CASE
                WHEN NVL(X.RCRLDS4_AGT_UG_SUB_TOTAL, 0)
                   + NVL(X.RCRLDS4_AGT_GR_SUB_TOTAL, 0) <> 0

                    THEN NVL(X.RCRLDS4_AGT_UG_SUB_TOTAL, 0)
                       + NVL(X.RCRLDS4_AGT_GR_SUB_TOTAL, 0)

                ELSE NVL(X.RCRLDS4_AGT_SUB_TOTAL, 0)
            END AS PRE_2026_SUB_USED,

            CASE
                WHEN NVL(X.RCRLDS4_AGT_UG_UNSUB_TOTAL, 0)
                   + NVL(X.RCRLDS4_AGT_GR_UNSUB_TOTAL, 0) <> 0

                    THEN NVL(X.RCRLDS4_AGT_UG_UNSUB_TOTAL, 0)
                       + NVL(X.RCRLDS4_AGT_GR_UNSUB_TOTAL, 0)

                ELSE NVL(X.RCRLDS4_AGT_UNSUB_TOTAL, 0)
            END AS PRE_2026_UNSUB_USED,
           
            /*
           =========================================================
           RAW NSLDS UNDERGRADUATE LOAN TOTALS
           =========================================================
            */

            NVL(X.RCRLDS4_AGT_UG_SUB_TOTAL, 0)
                AS UG_SUB_TOTAL,

            NVL(X.RCRLDS4_AGT_UG_UNSUB_TOTAL, 0)
                AS UG_UNSUB_TOTAL,

            NVL(X.RCRLDS4_AGT_UG_COMB_TOTAL, 0)
                AS UG_COMB_TOTAL,

            NVL(X.RCRLDS4_AGT_UG_UNAL_CONS_TOTAL, 0)
                AS UG_UNALLOCATED_CONSOL_TOTAL,

            /*
               =========================================================
               NEW GRADUATE AGGREGATE USAGE
               =========================================================
            */

            NVL(X.RCRLDS4_GRAD_AGT_TOTAL, 0)
            + NVL(X.RCRLDS4_GRAD_AGT_CONS_UNAL_TOT, 0)
                AS NEW_GRAD_AGG_USED,

            /*
               =========================================================
               NEW PROFESSIONAL AGGREGATE USAGE
               =========================================================
            */

            NVL(X.RCRLDS4_PROF_AGT_TOTAL, 0)
            + NVL(X.RCRLDS4_PROF_AGT_CONS_UNAL_TOT, 0)
                AS NEW_PROF_AGG_USED,

            /*
               Graduate + Professional usage for a borrower
               subject to the $200,000 cross-career framework.
            */

            NVL(X.RCRLDS4_GRAD_AGT_TOTAL, 0)
            + NVL(X.RCRLDS4_GRAD_AGT_CONS_UNAL_TOT, 0)
            + NVL(X.RCRLDS4_PROF_AGT_TOTAL, 0)
            + NVL(X.RCRLDS4_PROF_AGT_CONS_UNAL_TOT, 0)
                AS NEW_GRPROF_AGG_USED,
                
            /*
               =========================================================
               RAW NSLDS GRADUATE LOAN TOTALS
               =========================================================
            */

            NVL(X.RCRLDS4_AGT_GR_SUB_TOTAL, 0)
                AS GR_SUB_TOTAL,

            NVL(X.RCRLDS4_AGT_GR_UNSUB_TOTAL, 0)
                AS GR_UNSUB_TOTAL,

            NVL(X.RCRLDS4_AGT_GR_COMB_TOTAL, 0)
                AS GR_COMB_TOTAL,

            NVL(X.RCRLDS4_AGT_GR_UNAL_CONS_TOTAL, 0)
                AS GR_UNALLOCATED_CONSOL_TOTAL,

            /*
               =========================================================
               NEW $257,500 LIFETIME MAXIMUM
               =========================================================
            */

            NVL(X.RCRLDS4_LIFEMAX_LOAN_TOTAL, 0)
                AS LIFEMAX_LOAN_TOTAL,

            /*
               =========================================================
               NSLDS LIMIT FLAGS
               =========================================================
            */

            X.RCRLDS4_LIFEMAX_LOAN_LIMIT_FLG
                AS LIFEMAX_LOAN_LIMIT_FLG,

            X.RCRLDS4_GR_COMB_LOAN_LIMIT_FLG
                AS GR_COMB_LOAN_LIMIT_FLG,

            X.RCRLDS4_PR_COMB_LOAN_LIMIT_FLG
                AS PR_COMB_LOAN_LIMIT_FLG,

            X.RCRLDS4_LN_LIMIT_EXCEPT_FLG
                AS LOAN_LIMIT_EXCEPTION_FLG,

            X.RCRLDS4_DISB_DATE_FLG
                AS DISB_DATE_FLG,

            /*
               Source information for counselor/debugging review.
            */

            X.RCRLDS4_INFC_CODE AS INFC_CODE_USED,
            X.RCRLDS4_SEQ_NO AS SEQ_NO_USED,

            /*
               Older NSLDS values retained only for comparison.
            */

            NVL(X.RCRLDS4_AGT_COMB_PRIN_BAL, 0)
                AS OLD_LIFETIME_USED,

            NVL(X.RCRLDS4_AGT_SUB_OUT_PRIN_BAL, 0)
                AS OLD_LIFETIME_SUB_USED,

            NVL(X.RCRLDS4_AGT_UNSUB_OUT_PRIN_BAL, 0)
                AS OLD_LIFETIME_UNSUB_USED,
                
            NVL(X.RCRLDS4_AGT_COMB_TOTAL, 0)
                AS CURRENT_AGG_COMB_TOTAL

              FROM (
                SELECT
                    R.*,

                    ROW_NUMBER() OVER (
                        PARTITION BY R.RCRLDS4_PIDM
                        ORDER BY
                            R.RCRLDS4_SEQ_NO DESC,
                            R.RCRLDS4_SURROGATE_ID DESC
                    ) AS RN

                FROM RCRLDS4 R

                JOIN STUDENT_REC SR
                  ON SR.PIDM = R.RCRLDS4_PIDM
                 AND SR.AIDY_CODE = R.RCRLDS4_AIDY_CODE

                WHERE R.RCRLDS4_AIDY_CODE = :AIDY
                  AND R.RCRLDS4_INFC_CODE IN ('EDE','FAH')
                  AND R.RCRLDS4_CURR_REC_IND = 'Y'
            ) X

            WHERE X.RN = 1
    ),
    
            /*
           =========================================================
           HISTORICAL FAH AGGREGATE VALUES - VIEW ONLY

           Finds the latest FAH record containing the new UG/GR
           aggregate fields, regardless of current-record status.

           These values are NEVER used in eligibility calculations.
           =========================================================
        */
        FAH_AGG_HISTORY_VIEW AS (
            SELECT
                X.RCRLDS4_PIDM AS PIDM,

                X.RCRLDS4_AGT_UG_COMB_TOTAL
                    AS FAH_UG_COMB_TOTAL,

                X.RCRLDS4_AGT_UG_SUB_TOTAL
                    AS FAH_UG_SUB_TOTAL,

                X.RCRLDS4_AGT_UG_UNSUB_TOTAL
                    AS FAH_UG_UNSUB_TOTAL,

                X.RCRLDS4_AGT_UG_UNAL_CONS_TOTAL
                    AS FAH_UG_UNALLOC_CONS_TOTAL,

                X.RCRLDS4_AGT_GR_COMB_TOTAL
                    AS FAH_GR_COMB_TOTAL,

                X.RCRLDS4_AGT_GR_SUB_TOTAL
                    AS FAH_GR_SUB_TOTAL,

                X.RCRLDS4_AGT_GR_UNSUB_TOTAL
                    AS FAH_GR_UNSUB_TOTAL,

                X.RCRLDS4_AGT_GR_UNAL_CONS_TOTAL
                    AS FAH_GR_UNALLOC_CONS_TOTAL,

                X.RCRLDS4_GRAD_AGT_TOTAL
                    AS FAH_NEW_GRAD_AGG_TOTAL,

                /*
                   Total represented by the historical FAH
                   UG/GR aggregate breakdown.
                */
                NVL(X.RCRLDS4_AGT_UG_COMB_TOTAL, 0)
                + NVL(X.RCRLDS4_AGT_UG_UNAL_CONS_TOTAL, 0)
                + NVL(X.RCRLDS4_AGT_GR_COMB_TOTAL, 0)
                + NVL(X.RCRLDS4_AGT_GR_UNAL_CONS_TOTAL, 0)
                    AS FAH_TOTAL_AGG_USED,

                /*
                   Useful audit information.
                */
                X.RCRLDS4_INFC_CODE AS FAH_INFC_CODE_USED,

                X.RCRLDS4_SEQ_NO AS FAH_SEQ_NO_USED,

                X.RCRLDS4_CURR_REC_IND AS FAH_CURR_REC_USED

            FROM (
                SELECT
                    R.*,

                    ROW_NUMBER() OVER (
                        PARTITION BY R.RCRLDS4_PIDM
                        ORDER BY
                            R.RCRLDS4_SEQ_NO DESC,
                            R.RCRLDS4_SURROGATE_ID DESC
                    ) AS RN

                FROM RCRLDS4 R

                JOIN STUDENT_REC SR
                  ON SR.PIDM = R.RCRLDS4_PIDM
                 AND SR.AIDY_CODE = R.RCRLDS4_AIDY_CODE

                WHERE R.RCRLDS4_AIDY_CODE = :AIDY
                  AND R.RCRLDS4_INFC_CODE = 'FAH'

                  AND COALESCE(
                          R.RCRLDS4_AGT_UG_COMB_TOTAL,
                          R.RCRLDS4_AGT_UG_SUB_TOTAL,
                          R.RCRLDS4_AGT_UG_UNSUB_TOTAL,
                          R.RCRLDS4_AGT_UG_UNAL_CONS_TOTAL,
                          R.RCRLDS4_AGT_GR_COMB_TOTAL,
                          R.RCRLDS4_AGT_GR_SUB_TOTAL,
                          R.RCRLDS4_AGT_GR_UNSUB_TOTAL,
                          R.RCRLDS4_AGT_GR_UNAL_CONS_TOTAL,
                          R.RCRLDS4_GRAD_AGT_TOTAL
                      ) IS NOT NULL
            ) X

            WHERE X.RN = 1
        ),
        
    ROBUSDF_DATA AS (
        SELECT
            ROBUSDF_PIDM,
            ROBUSDF_AIDY_CODE,
            ROBUSDF_VALUE_110,
            ROBUSDF_VALUE_118,
            ROBUSDF_VALUE_119,
            ROBUSDF_VALUE_120
        FROM ROBUSDF
         JOIN STUDENT_REC SR
         ON SR.PIDM = ROBUSDF_PIDM
        WHERE ROBUSDF_AIDY_CODE = :AIDY
    ),

    LEGACY_PROGRAM_DATA AS (
        SELECT
            R.ROBNYUD_PIDM,

            R.ROBNYUD_VALUE_24 AS LEGACY_PROGRAM_1,
            R.ROBNYUD_VALUE_25 AS LEGACY_PROGRAM_1_ETTC_TERMS,
            R.ROBNYUD_VALUE_26 AS LEGACY_PROGRAM_1_ETTC_YEARS,
            R.ROBNYUD_VALUE_27 AS LEGACY_PROGRAM_1_ENDED,

            R.ROBNYUD_VALUE_28 AS LEGACY_PROGRAM_2,
            R.ROBNYUD_VALUE_29 AS LEGACY_PROGRAM_2_ETTC_TERMS,
            R.ROBNYUD_VALUE_30 AS LEGACY_PROGRAM_2_ETTC_YEARS,
            R.ROBNYUD_VALUE_31 AS LEGACY_PROGRAM_2_ENDED,

            R.ROBNYUD_VALUE_32 AS LEGACY_PROGRAM_3,
            R.ROBNYUD_VALUE_33 AS LEGACY_PROGRAM_3_ETTC_TERMS,
            R.ROBNYUD_VALUE_34 AS LEGACY_PROGRAM_3_ETTC_YEARS,
            R.ROBNYUD_VALUE_35 AS LEGACY_PROGRAM_3_ENDED,

            R.ROBNYUD_VALUE_36 AS LEGACY_PROGRAM_4,
            R.ROBNYUD_VALUE_37 AS LEGACY_PROGRAM_4_ETTC_TERMS,
            R.ROBNYUD_VALUE_38 AS LEGACY_PROGRAM_4_ETTC_YEARS,
            R.ROBNYUD_VALUE_39 AS LEGACY_PROGRAM_4_ENDED,

            CASE
                WHEN (
                        R.ROBNYUD_VALUE_24 IS NOT NULL
                    AND UPPER(TRIM(R.ROBNYUD_VALUE_27)) = 'N'
                     )
                  OR (
                        R.ROBNYUD_VALUE_28 IS NOT NULL
                    AND UPPER(TRIM(R.ROBNYUD_VALUE_31)) = 'N'
                     )
                  OR (
                        R.ROBNYUD_VALUE_32 IS NOT NULL
                    AND UPPER(TRIM(R.ROBNYUD_VALUE_35)) = 'N'
                     )
                  OR (
                        R.ROBNYUD_VALUE_36 IS NOT NULL
                    AND UPPER(TRIM(R.ROBNYUD_VALUE_39)) = 'N'
                     )
                    THEN 'Y'

                ELSE 'N'
            END AS KSU_LEGACY_ACTIVE

        FROM ROBNYUD R

        JOIN STUDENT_REC SR
          ON SR.PIDM = R.ROBNYUD_PIDM

        WHERE COALESCE(
                  R.ROBNYUD_VALUE_24,
                  R.ROBNYUD_VALUE_28,
                  R.ROBNYUD_VALUE_32,
                  R.ROBNYUD_VALUE_36
              ) IS NOT NULL
    ),

    NSLDS_TRACKING AS (
        SELECT
            RRRAREQ_PIDM,
            RRRAREQ_TREQ_CODE AS NSLDS_TREQ,
            RRRAREQ_TRST_CODE AS NSLDS_STATUS,
            TRUNC(RRRAREQ_ACTIVITY_DATE) AS NSLDS_DATE

        FROM (
            SELECT
                R.RRRAREQ_PIDM,
                R.RRRAREQ_TREQ_CODE,
                R.RRRAREQ_TRST_CODE,
                R.RRRAREQ_ACTIVITY_DATE,

                ROW_NUMBER() OVER (
                    PARTITION BY R.RRRAREQ_PIDM
                    ORDER BY
                        R.RRRAREQ_ACTIVITY_DATE DESC,
                        R.RRRAREQ_TREQ_CODE
                ) AS RN

            FROM RRRAREQ R

            JOIN STUDENT_REC SR
              ON SR.PIDM = R.RRRAREQ_PIDM
             AND SR.AIDY_CODE = R.RRRAREQ_AIDY_CODE

            WHERE R.RRRAREQ_AIDY_CODE = :AIDY

              AND R.RRRAREQ_TREQ_CODE IN (
                  'NSLDS',
                  'NSLDSA',
                  'NSLDSB',
                  'NSLDSC',
                  'NSLDSD',
                  'NSLDSF',
                  'NSLDSG',
                  'NSLDSN',
                  'NSLDSO',
                  'NSLDSP',
                  'NSLDSR'
              )
        )

        WHERE RN = 1
    ),

    RORENRL_FLAGS AS (
        SELECT
            RE.RORENRL_PIDM,

            MAX(CASE WHEN RE.RORENRL_CONSORTIUM_IND = 'Y' THEN 'Y' ELSE 'N' END) AS HAS_CONSORTIUM_IND_Y,

            SUM(CASE WHEN RE.RORENRL_ENRR_CODE = 'FEDAID'
                     THEN NVL(RE.RORENRL_FINAID_BILL_HR, 0)
                     ELSE 0
                END) AS TERM_TOTAL_FINAID_BILL_HR_FEDAID,

            SUM(CASE WHEN RE.RORENRL_ENRR_CODE = 'FEDAID'
                     THEN NVL(RE.RORENRL_FINAID_ADJ_HR, 0)
                     ELSE 0
                END) AS TERM_TOTAL_FINAID_ADJ_HR_FEDAID,

            SUM(CASE WHEN RE.RORENRL_ENRR_CODE = 'STANDARD'
                     THEN NVL(RE.RORENRL_FINAID_BILL_HR, 0)
                     ELSE 0
                END) AS TERM_TOTAL_FINAID_BILL_HR_STANDARD,

            SUM(CASE WHEN RE.RORENRL_ENRR_CODE = 'STANDARD'
                     THEN NVL(RE.RORENRL_FINAID_ADJ_HR, 0)
                     ELSE 0
                END) AS TERM_TOTAL_FINAID_ADJ_HR_STANDARD
                
        FROM RORENRL RE
        JOIN STUDENT_REC SR
          ON SR.PIDM = RE.RORENRL_PIDM

        WHERE RE.RORENRL_TERM_CODE = :TERM

        GROUP BY RE.RORENRL_PIDM
    ),

    HOLDS AS (
        SELECT
            PIDM,
            SR_HOLD,
            SR_HOLD_FROM,
            SR_HOLD_TO,
            SR_HOLD_TERM
        FROM (
            SELECT
                RORHOLD_PIDM AS PIDM,
                RORHOLD_HOLD_CODE AS SR_HOLD,
                RORHOLD_FROM_DATE AS SR_HOLD_FROM,
                RORHOLD_TO_DATE AS SR_HOLD_TO,
                RORHOLD_TERM_CODE AS SR_HOLD_TERM,

                ROW_NUMBER() OVER (
                    PARTITION BY
                        RORHOLD_PIDM,
                        RORHOLD_TERM_CODE
                    ORDER BY
                        RORHOLD_FROM_DATE DESC,
                        RORHOLD_TO_DATE DESC NULLS FIRST
                ) AS RN

            FROM RORHOLD
            WHERE RORHOLD_HOLD_CODE = 'SR'
              AND RORHOLD_TERM_CODE = :TERM
        )
        WHERE RN = 1
    ),

    BASE_RAW AS (
        SELECT /*+ MATERIALIZE */
            SR.PIDM,
            SPRIDEN.SPRIDEN_ID,
            SPRIDEN.SPRIDEN_LAST_NAME,
            SPRIDEN.SPRIDEN_FIRST_NAME,
            SR.AIDY_CODE,
            SR.PCKG_COMP_DATE,
            SR.PACKAGING_GROUP,
            SR.TRACKING_GROUP,
            SR.AID_PERIOD,
            SR.YEAR_EXPECTED_ENROLLMENT,
            SR.TERMS_IN_PERIOD,
            SR.LOAN_PERIOD_TYPE,

            SL.SGBSTDN_LEVL_CODE AS CAREER,
            SL.SGBSTDN_STYP_CODE AS STUDENT_TYPE,
            SL.SGBSTDN_PROGRAM_1 AS PROGRAM,
            SL.PROGRAM_TERM,

            /* KSU locally maintained legacy/interim program information */
            LPD.LEGACY_PROGRAM_1,
            LPD.LEGACY_PROGRAM_1_ETTC_TERMS,
            LPD.LEGACY_PROGRAM_1_ETTC_YEARS,
            LPD.LEGACY_PROGRAM_1_ENDED,

            LPD.LEGACY_PROGRAM_2,
            LPD.LEGACY_PROGRAM_2_ETTC_TERMS,
            LPD.LEGACY_PROGRAM_2_ETTC_YEARS,
            LPD.LEGACY_PROGRAM_2_ENDED,

            LPD.LEGACY_PROGRAM_3,
            LPD.LEGACY_PROGRAM_3_ETTC_TERMS,
            LPD.LEGACY_PROGRAM_3_ETTC_YEARS,
            LPD.LEGACY_PROGRAM_3_ENDED,

            LPD.LEGACY_PROGRAM_4,
            LPD.LEGACY_PROGRAM_4_ETTC_TERMS,
            LPD.LEGACY_PROGRAM_4_ETTC_YEARS,
            LPD.LEGACY_PROGRAM_4_ENDED,

            NVL(LPD.KSU_LEGACY_ACTIVE, 'N') AS KSU_LEGACY_ACTIVE,

            /* Current NSLDS tracking requirement */
            NT.NSLDS_TREQ,
            NT.NSLDS_STATUS,
            NT.NSLDS_DATE,

            LD.DEPENDENCY_STATUS,
            LD.GRADE_LEVEL,
            LD.SAI,

            NVL(FH.SMR_FEDAID_HOURS, 0) AS FEDAID_HRS_SMR,
            NVL(FH.FAL_FEDAID_HOURS, 0) AS FEDAID_HRS_FAL,
            NVL(FH.SPR_FEDAID_HOURS, 0) AS FEDAID_HRS_SPR,

            /* Internal prior-term SOR hours. These are used by the
               SOR_HOURS_* logic but are not displayed as new report columns. */
            NVL(SPH.SMR_SOR_PRIOR_HOURS, 0) AS SMR_SOR_PRIOR_HOURS,
            NVL(SPH.FAL_SOR_PRIOR_HOURS, 0) AS FAL_SOR_PRIOR_HOURS,
            NVL(SPH.SPR_SOR_PRIOR_HOURS, 0) AS SPR_SOR_PRIOR_HOURS,

            NVL(RH.SMR_REGISTERED_HOURS, 0) AS SMR_REGISTERED_HOURS,
            NVL(RH.FAL_REGISTERED_HOURS, 0) AS FAL_REGISTERED_HOURS,
            NVL(RH.SPR_REGISTERED_HOURS, 0) AS SPR_REGISTERED_HOURS,

            CASE
                WHEN SR.YEAR_EXPECTED_ENROLLMENT IN ('1','2','3','4') THEN SR.YEAR_EXPECTED_ENROLLMENT
                ELSE '5'
            END AS XES_CLEAN,

            CASE WHEN SL.SGBSTDN_LEVL_CODE IN ('GR','PR') THEN 8 ELSE 12 END AS FT_HOURS_PER_TERM,
            CASE WHEN SL.SGBSTDN_LEVL_CODE IN ('GR','PR') THEN 16 ELSE 24 END AS FT_HOURS_ACADEMIC_YEAR,

            NVL(AA.AY_SUB_OFFER, 0) AS CURRENT_AY_SUBSIDIZED_ALREADY_OFFERED,
            NVL(AA.AY_SUB_PAID, 0) AS CURRENT_AY_SUB_PAID,
            NVL(AA.AY_UNSUB_OFFER, 0) AS CURRENT_AY_UNSUBSIDIZED_ALREADY_OFFERED,
            NVL(AA.AY_UNSUB_PAID, 0) AS CURRENT_AY_UNSUB_PAID,
            NVL(AA.ALL_OTHER_AY_AID, 0) AS ALL_OTHER_AY_AID,
            NVL(AA.NEED_BASED_AY_AID, 0) AS NEED_BASED_AY_AID,
            NVL(AA.MERIT_INSTITUTIONAL_AY_AID, 0) AS MERIT_INSTITUTIONAL_AY_AID,
            NVL(AA.FWS_OFFERED, 0) AS FWS_OFFERED,
            NVL(AA.TEACH_OFFERED, 0) AS TEACH_OFFERED,
            NVL(AA.PRIVATE_LOAN_OFFERED, 0) AS PRIVATE_LOAN_OFFERED,

            CASE WHEN SL.SGBSTDN_LEVL_CODE = 'UG' THEN NVL(AA.PLUS_OFFERED, 0) ELSE 0 END AS AY_PARENT_PLUS_TOTAL,
            CASE WHEN SL.SGBSTDN_LEVL_CODE IN ('GR','PR') THEN NVL(AA.PLUS_OFFERED, 0) ELSE 0 END AS AY_GRAD_PROF_PLUS_TOTAL,

            NVL(TA.TERM_SUB_OFFER, 0) AS TERM_SUB_OFFER,
            NVL(TA.TERM_SUB_PAID, 0) AS TERM_SUB_PAID,

            NVL(TA.TERM_UNSUB_OFFER, 0) AS TERM_UNSUB_OFFER,
            NVL(TA.TERM_UNSUB_PAID, 0) AS TERM_UNSUB_PAID,

            NVL(TA.TERM_TOTAL_OFFER, 0) AS TERM_TOTAL_OFFER,
            
            NVL(SLH.SMR_SUB_PAID, 0)   AS SMR_SUB_PAID,
            NVL(SLH.SMR_UNSUB_PAID, 0) AS SMR_UNSUB_PAID,
            
            NVL(ALL_OTHER_TERM_AID, 0) AS ALL_OTHER_TERM_AID,
            NVL(TERM_PLUS_OFFERED, 0) AS TERM_PLUS_OFFERED,

            NVL(ND.COA_TOTAL, 0) AS COA_TOTAL,
            NVL(ND.COA_REMAINING, NVL(ND.COA_TOTAL, 0)) AS COA_REMAINING,
            NVL(ND.UNMET_NEED, 0) AS UNMET_NEED,
            NVL(ND.OFA_RESOURCE,0) AS OTHER_AID_RESOURCES,

            RU.ROBUSDF_VALUE_110,
            RU.ROBUSDF_VALUE_118,
            RU.ROBUSDF_VALUE_119,
            RU.ROBUSDF_VALUE_120,

            NVL(RE.HAS_CONSORTIUM_IND_Y, 'N') AS HAS_CONSORTIUM_IND_Y,
            RE.TERM_TOTAL_FINAID_BILL_HR_FEDAID,
            RE.TERM_TOTAL_FINAID_ADJ_HR_FEDAID,
            RE.TERM_TOTAL_FINAID_BILL_HR_STANDARD,
            RE.TERM_TOTAL_FINAID_ADJ_HR_STANDARD,
            HOLDS.SR_HOLD,
            HOLDS.SR_HOLD_FROM,
            HOLDS.SR_HOLD_TO,
            HOLDS.SR_HOLD_TERM,
            TA.TERM_PELL_OFFER,
            TA.TERM_PELL_PAID,
            NVL(PLUS_OFFERED, 0) AS PLUS_OFFERED

        FROM STUDENT_REC SR
        JOIN SPRIDEN
          ON SPRIDEN.SPRIDEN_PIDM = SR.PIDM
         AND SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
         
        LEFT JOIN STUDENT_LEVEL SL
          ON SL.SGBSTDN_PIDM = SR.PIDM
          
        LEFT JOIN STUDENT_LIMIT_DATA LD
          ON LD.RCRAPP2_PIDM = SR.PIDM
         AND LD.RCRAPP1_AIDY_CODE = SR.AIDY_CODE
         
        LEFT JOIN FEDAID_HOURS FH
          ON FH.PIDM = SR.PIDM
         AND FH.AIDY_CODE = SR.AIDY_CODE

        LEFT JOIN SOR_PRIOR_TERM_HOURS SPH
          ON SPH.PIDM = SR.PIDM
         
        LEFT JOIN REGISTERED_HOURS RH
          ON RH.SFRSTCR_PIDM = SR.PIDM
                    
        LEFT JOIN ANNUAL_AWARDS AA
          ON AA.PIDM = SR.PIDM
         AND AA.AIDY_CODE = SR.AIDY_CODE
         
        LEFT JOIN TERM_AWARDS TA
          ON TA.PIDM = SR.PIDM
         AND TA.AIDY_CODE = SR.AIDY_CODE
         AND TA.TERM_CODE = :TERM
         
        LEFT JOIN SUMMER_LOAN_HISTORY SLH
          ON SLH.PIDM = SR.PIDM
         AND SLH.AIDY_CODE = SR.AIDY_CODE
         
        LEFT JOIN NEED_DATA ND
          ON ND.PIDM = SR.PIDM
         AND ND.AIDY_CODE = SR.AIDY_CODE
         
        LEFT JOIN ROBUSDF_DATA RU
          ON RU.ROBUSDF_PIDM = SR.PIDM
         AND RU.ROBUSDF_AIDY_CODE = SR.AIDY_CODE
         
         LEFT JOIN LEGACY_PROGRAM_DATA LPD
          ON LPD.ROBNYUD_PIDM = SR.PIDM

         LEFT JOIN NSLDS_TRACKING NT
          ON NT.RRRAREQ_PIDM = SR.PIDM

        LEFT JOIN RORENRL_FLAGS RE
          ON RE.RORENRL_PIDM = SR.PIDM
              
        LEFT JOIN HOLDS
          ON HOLDS.PIDM = SR.PIDM
         AND HOLDS.SR_HOLD_TERM = :TERM
         
         WHERE RH.CURR_REGISTERED_HOURS > 0
    ),

    /*
       ============================================================
       SOR HOURS BY TERM POSITION
       ============================================================

       The existing :TERM parameter determines whether each aid-year
       term is previous, current, or future. No manual switch and no
       additional report parameter is required.

       FALL RUN (:TERM = :FAL_TERM)
           Summer = PREVIOUS -> prior-term academic-history hours
           Fall   = CURRENT  -> actual FEDAID hours
           Spring = FUTURE   -> FEDAID if present, otherwise XES

       SPRING RUN (:TERM = :SPR_TERM)
           Summer = PREVIOUS -> prior-term academic-history hours
           Fall   = PREVIOUS -> prior-term academic-history hours
           Spring = CURRENT  -> actual FEDAID hours

       Summer therefore remains a previous term when the report is
       later run for Spring.
    */
    BASE AS (
        SELECT
            BR.*,

            CASE BR.XES_CLEAN
                WHEN '1' THEN 1.00
                WHEN '2' THEN 0.75
                WHEN '3' THEN 0.50
                WHEN '4' THEN 0.25
                ELSE 0
            END AS XES_MULTIPLIER,

            /* Summer: previous for Fall and Spring runs; current for Summer. */
            CASE
                WHEN BR.AID_PERIOD NOT IN
                     ('SUMMER', 'SMRFAL', 'SMRSPR', 'SMFLSP')
                    THEN 0

                WHEN :TERM IN (:FAL_TERM, :SPR_TERM)
                    THEN NVL(BR.SMR_SOR_PRIOR_HOURS, 0)

                WHEN :TERM = :SMR_TERM
                    THEN NVL(BR.FEDAID_HRS_SMR, 0)

                ELSE 0
            END AS SOR_HOURS_SMR,
            
            CASE
                WHEN BR.AID_PERIOD NOT IN
                     ('SUMMER', 'SMRFAL', 'SMRSPR', 'SMFLSP')
                    THEN 'NOT IN AID PERIOD'

                WHEN :TERM > :SMR_TERM
                    THEN 'PRIOR TERM - GRADED'

                WHEN :TERM = :SMR_TERM
                    THEN 'CURRENT TERM - FEDAID'

                WHEN NVL(BR.FEDAID_HRS_SMR, 0) > 0
                    THEN 'FUTURE TERM - FEDAID'

                ELSE 'FUTURE TERM - EXPECTED ENROLLMENT'
            END AS SOR_HOURS_SMR_SOURCE,

            /* Fall: future in Summer, current in Fall, previous in Spring. */
            CASE
                WHEN BR.AID_PERIOD NOT IN
                     ('FALL', 'SMRFAL', 'FA/SPR', 'SMFLSP')
                    THEN 0

                WHEN :TERM = :SPR_TERM
                    THEN NVL(BR.FAL_SOR_PRIOR_HOURS, 0)

                WHEN :TERM = :FAL_TERM
                    THEN NVL(BR.FEDAID_HRS_FAL, 0)

                WHEN :TERM = :SMR_TERM
                 AND NVL(BR.FEDAID_HRS_FAL, 0) > 0
                    THEN NVL(BR.FEDAID_HRS_FAL, 0)

                WHEN :TERM = :SMR_TERM
                    THEN ROUND(
                        BR.FT_HOURS_PER_TERM *
                        CASE BR.XES_CLEAN
                            WHEN '1' THEN 1.00
                            WHEN '2' THEN 0.75
                            WHEN '3' THEN 0.50
                            WHEN '4' THEN 0.25
                            ELSE 0
                        END,
                        2
                    )

                ELSE 0
            END AS SOR_HOURS_FAL,
            
            CASE
                WHEN BR.AID_PERIOD NOT IN ('FALL', 'SMRFAL', 'FA/SPR', 'SMFLSP')
                    THEN 'NOT IN AID PERIOD'

                WHEN :TERM > :FAL_TERM
                    THEN 'PRIOR TERM - GRADED'

                WHEN :TERM = :FAL_TERM
                    THEN 'CURRENT TERM - FEDAID'

                WHEN NVL(BR.FEDAID_HRS_FAL, 0) > 0
                    THEN 'FUTURE TERM - FEDAID'

                ELSE 'FUTURE TERM - XES'
            END AS SOR_HOURS_FAL_SOURCE,

            /* Spring: future in Summer/Fall and current in Spring. */
            CASE
                WHEN BR.AID_PERIOD NOT IN
                     ('SPRING', 'SMRSPR', 'FA/SPR', 'SMFLSP')
                    THEN 0

                WHEN :TERM = :SPR_TERM
                    THEN NVL(BR.FEDAID_HRS_SPR, 0)

                WHEN :TERM IN (:SMR_TERM, :FAL_TERM)
                 AND NVL(BR.FEDAID_HRS_SPR, 0) > 0
                    THEN NVL(BR.FEDAID_HRS_SPR, 0)

                WHEN :TERM IN (:SMR_TERM, :FAL_TERM)
                    THEN ROUND(
                        BR.FT_HOURS_PER_TERM *
                        CASE BR.XES_CLEAN
                            WHEN '1' THEN 1.00
                            WHEN '2' THEN 0.75
                            WHEN '3' THEN 0.50
                            WHEN '4' THEN 0.25
                            ELSE 0
                        END,
                        2
                    )

                ELSE 0
            END AS SOR_HOURS_SPR,
            
            CASE
                WHEN BR.AID_PERIOD NOT IN ('SPRING', 'SMRSPR', 'FA/SPR', 'SMFLSP')
                    THEN 'NOT IN AID PERIOD'

                WHEN :TERM > :SPR_TERM
                    THEN 'PRIOR TERM - GRADED'

                WHEN :TERM = :SPR_TERM
                    THEN 'CURRENT TERM - FEDAID'

                WHEN NVL(BR.FEDAID_HRS_SPR, 0) > 0
                    THEN 'FUTURE TERM - FEDAID'

                ELSE 'FUTURE TERM - XES'
            END AS SOR_HOURS_SPR_SOURCE

        FROM BASE_RAW BR
    ),

    BASE_WITH_HOURS AS (
        SELECT
            B.*,

            /*
               Hours used to calculate the Schedule of Reductions.
               These can span the entire loan period.
            */
            CASE
                WHEN B.AID_PERIOD = 'SUMMER'
                    THEN NVL(B.SOR_HOURS_SMR, 0)

                WHEN B.AID_PERIOD = 'FALL'
                    THEN NVL(B.SOR_HOURS_FAL, 0)

                WHEN B.AID_PERIOD = 'SPRING'
                    THEN NVL(B.SOR_HOURS_SPR, 0)

                WHEN B.AID_PERIOD = 'SMRFAL'
                    THEN NVL(B.SOR_HOURS_SMR, 0)
                       + NVL(B.SOR_HOURS_FAL, 0)

                WHEN B.AID_PERIOD = 'SMRSPR'
                    THEN NVL(B.SOR_HOURS_SMR, 0)
                       + NVL(B.SOR_HOURS_SPR, 0)

                WHEN B.AID_PERIOD = 'FA/SPR'
                    THEN NVL(B.SOR_HOURS_FAL, 0)
                       + NVL(B.SOR_HOURS_SPR, 0)

                WHEN B.AID_PERIOD = 'SMFLSP'
                    THEN NVL(B.SOR_HOURS_SMR, 0)
                       + NVL(B.SOR_HOURS_FAL, 0)
                       + NVL(B.SOR_HOURS_SPR, 0)

                ELSE 0
            END AS HOURS_USED_FOR_SOR,

            /*
               Actual FED AID hours for the term being reviewed.

               Do NOT use estimated/XES hours for the current
               disbursement half-time test.
            */
            CASE
                WHEN :TERM = :SMR_TERM
                    THEN NVL(B.FEDAID_HRS_SMR, 0)

                WHEN :TERM = :FAL_TERM
                    THEN NVL(B.FEDAID_HRS_FAL, 0)

                WHEN :TERM = :SPR_TERM
                    THEN NVL(B.FEDAID_HRS_SPR, 0)

                ELSE 0
            END AS CURRENT_TERM_FEDAID_HOURS

        FROM BASE B
    ),

    BASE_WITH_LOOKUP AS (
        SELECT
            B.*,

            CASE
                WHEN B.CAREER IN ('GR','PR')
                    THEN 'ANY'

                WHEN UPPER(NVL(B.DEPENDENCY_STATUS, ''))
                     IN ('I','INDEPENDENT')
                    THEN 'INDEPENDENT'

                ELSE 'DEPENDENT'
            END AS DEPENDENCY_BUCKET,

            CASE
                WHEN B.CAREER IN ('GR','PR')
                    THEN 'ANY'

                ELSE B.GRADE_LEVEL
            END AS GRADE_BUCKET,
                    /*
                New 2026-27 graduate/professional loan-level code.

                       8  = Graduate, never Professional
                       9  = Graduate, was Professional
                       10 = Professional, never Graduate
                       11 = Professional, was Graduate
                       12 = Graduate concurrent enrollment
                       13 = Professional concurrent enrollment
                    */
            CASE
                WHEN B.CAREER IN ('GR','PR')
                    THEN TRIM(B.GRADE_LEVEL)
                ELSE NULL
            END AS GRPR_LIMIT_LEVEL,

            /*
               Half-time is a CURRENT TERM disbursement requirement.

               Keep this separate from HOURS_USED_FOR_SOR.
            */
            CASE
                WHEN B.CAREER IN ('GR','PR')
                 AND NVL(B.CURRENT_TERM_FEDAID_HOURS, 0) >= 4
                    THEN 'Y'

                WHEN B.CAREER = 'UG'
                 AND NVL(B.CURRENT_TERM_FEDAID_HOURS, 0) >= 6
                    THEN 'Y'

                ELSE 'N'
            END AS HALF_TIME_ELIGIBLE

        FROM BASE_WITH_HOURS B
    ),
        /*
           ============================================================
           OFA / SAI REPLACEMENT BASE
           ============================================================

           Working calculation using the KSU fund categories
           currently identifiable in Banner.
        */
        OFA_BASE AS (
            SELECT
                B.*,

                /*
                   Negative SAI is treated as zero for
                   need-based packaging.
                */
                GREATEST(
                    NVL(B.SAI, 0),
                    0
                ) AS SAI_USED_FOR_NEED,

                /*
                   Known aid currently allowed to replace SAI:

                     TEACH
                     PLUS
                     Private education loans

                   Do NOT include need-based aid here.
                */
                NVL(B.TEACH_OFFERED, 0)
                + NVL(B.PLUS_OFFERED, 0)
                + NVL(B.PRIVATE_LOAN_OFFERED, 0)
                    AS SAI_REPLACE_ELIGIBLE_AID

            FROM BASE_WITH_LOOKUP B
        ),

        /*
           ============================================================
           OFA / SUBSIDIZED NEED CALCULATION
           ============================================================
        */
        OFA_CALC AS (
            SELECT
                O.*,

                /*
                   Only the lesser of:

                     student's SAI
                     or
                     eligible SAI-replacing aid

                   can be excluded from OFA as SAI replacement.
                */
                LEAST(
                    O.SAI_USED_FOR_NEED,
                    O.SAI_REPLACE_ELIGIBLE_AID
                ) AS SAI_REPLACEMENT_USED,

                /*
                   OFA used to calculate Subsidized need.

                   Begin with ALL OTHER AID and remove only
                   the amount actually being used to replace SAI.
                */
                GREATEST(
                    NVL(O.ALL_OTHER_AY_AID, 0)
                    -
                    LEAST(
                        O.SAI_USED_FOR_NEED,
                        O.SAI_REPLACE_ELIGIBLE_AID
                    ),
                    0
                ) AS OFA_FOR_SUB_NEED,

                /*
                   Subsidized financial need:

                       COA
                     - SAI
                     - OFA
                */
                GREATEST(
                    NVL(O.COA_TOTAL, 0)
                    - O.SAI_USED_FOR_NEED
                    -
                    GREATEST(
                        NVL(O.ALL_OTHER_AY_AID, 0)
                        -
                        LEAST(
                            O.SAI_USED_FOR_NEED,
                            O.SAI_REPLACE_ELIGIBLE_AID
                        ),
                        0
                    ),
                    0
                ) AS SUBSIDIZED_NEED,

                /*
                   Total Direct Loan COA room.

                   All other aid still consumes COA.

                   SAI is NOT subtracted.
                */
                GREATEST(
                    NVL(O.COA_TOTAL, 0)
                    - NVL(O.ALL_OTHER_AY_AID, 0),
                    0
                ) AS TOTAL_DL_COA_ROOM

            FROM OFA_BASE O
        ),

    CALC_BASE AS (
        SELECT
            B.*,

            L.ANNUAL_TOTAL_LIMIT AS STANDARD_ANNUAL_LIMIT,
            L.ANNUAL_SUB_LIMIT AS STANDARD_SUB_LIMIT,

            /*
               Keep the institution's existing single-term factor.

               NOTE:
               The July FAQ establishes that a one-term loan limit
               must be applied before SOR, but it does not itself
               establish that .50 is the correct factor.
            */
            CASE
                WHEN B.AID_PERIOD IN ('SUMMER', 'FALL', 'SPRING')
                    THEN 0.50
                ELSE 1.00
            END AS LOAN_PERIOD_FACTOR,

            CASE
                WHEN B.AID_PERIOD IN ('SUMMER', 'FALL', 'SPRING')
                    THEN B.FT_HOURS_PER_TERM
                ELSE B.FT_HOURS_ACADEMIC_YEAR
            END AS FT_HOURS_FOR_SOR,

            /*
               SOR percentage:
               6 / 24 = .25
               10 / 24 = .4167 -> .42
               18 / 24 = .75
            */
            CASE
                WHEN NVL(B.HOURS_USED_FOR_SOR, 0) <= 0
                    THEN 0

                WHEN (
                    CASE
                        WHEN B.AID_PERIOD IN ('SUMMER', 'FALL', 'SPRING')
                            THEN B.FT_HOURS_PER_TERM
                        ELSE B.FT_HOURS_ACADEMIC_YEAR
                    END
                ) = 0
                    THEN 0

                ELSE ROUND(
                    LEAST( 1,
                        NVL(B.HOURS_USED_FOR_SOR, 0) /
                        (CASE WHEN B.AID_PERIOD IN ('SUMMER', 'FALL', 'SPRING')
                                THEN B.FT_HOURS_PER_TERM
                                ELSE B.FT_HOURS_ACADEMIC_YEAR
                            END
                        )
                    ),
                    2
                )
            END AS SOR_PCT,

            /*
               Subsidized need cap using adjusted OFA.
            */
            B.SUBSIDIZED_NEED
                AS COA_MINUS_SAI_MINUS_OTHER_AID,

            /*
               Total Direct Loan COA room.
            */
            B.TOTAL_DL_COA_ROOM
                AS COA_MINUS_OTHER_AID,

        /*
           Which aggregate history applies to THIS student?
        */
        CASE
            /* Undergraduate */
            WHEN B.CAREER = 'UG' THEN NVL(LL.UG_COMBINED_USED, 0)

            /* Interim / legacy GR or PR */
            WHEN B.CAREER IN ('GR','PR') AND B.KSU_LEGACY_ACTIVE = 'Y' THEN NVL(LL.PRE_2026_COMBINED_USED, 0)

            /* New Graduate - never Professional */
            WHEN B.CAREER = 'GR' AND B.GRPR_LIMIT_LEVEL = 'A' THEN NVL(LL.NEW_GRAD_AGG_USED, 0)

            /* New Graduate - was/is Professional */
            WHEN B.CAREER = 'GR' AND B.GRPR_LIMIT_LEVEL IN ('B','E') THEN NVL(LL.NEW_GRPROF_AGG_USED, 0)

            /* New Professional */
            WHEN B.CAREER = 'PR' AND B.GRPR_LIMIT_LEVEL IN ('C','D','F') THEN NVL(LL.NEW_GRPROF_AGG_USED, 0)
            ELSE 0 END AS LIFETIME_USED,

            /*
               Subsidized aggregate limit is relevant to UG and
               to the old legacy aggregate framework.

               New GR/PR borrowers cannot receive Subsidized loans.
            */
        CASE
            WHEN B.CAREER = 'UG' THEN NVL(LL.UG_SUB_USED, 0)
            WHEN B.CAREER IN ('GR','PR')
             AND B.KSU_LEGACY_ACTIVE = 'Y'
                THEN NVL(LL.PRE_2026_SUB_USED, 0)

            ELSE 0
        END AS LIFETIME_SUB_USED,

        /*
           Informational unsubsidized portion.
        */
        CASE
            WHEN B.CAREER = 'UG'
                THEN NVL(LL.UG_UNSUB_USED, 0)

            WHEN B.CAREER IN ('GR','PR')
         AND B.KSU_LEGACY_ACTIVE = 'Y'
            THEN NVL(LL.PRE_2026_UNSUB_USED, 0)

            WHEN B.CAREER = 'GR'
             AND B.GRPR_LIMIT_LEVEL = 'A'
                THEN NVL(LL.NEW_GRAD_AGG_USED, 0)

            WHEN B.CAREER = 'GR'
             AND B.GRPR_LIMIT_LEVEL IN ('B','E')
                THEN NVL(LL.NEW_GRPROF_AGG_USED, 0)

            WHEN B.CAREER = 'PR'
             AND B.GRPR_LIMIT_LEVEL IN ('C','D','F')
                THEN NVL(LL.NEW_GRPROF_AGG_USED, 0)

            ELSE 0
                END AS LIFETIME_UNSUB_USED,

                NVL(LL.LIFEMAX_LOAN_TOTAL, 0)
                    AS LIFEMAX_LOAN_TOTAL,

                LL.LIFEMAX_LOAN_LIMIT_FLG,
                LL.GR_COMB_LOAN_LIMIT_FLG,
                LL.PR_COMB_LOAN_LIMIT_FLG,
                LL.LOAN_LIMIT_EXCEPTION_FLG,
                LL.DISB_DATE_FLG,

                CASE
                    WHEN B.CAREER = 'UG'
                        THEN 'STANDARD_UG'
                    WHEN B.KSU_LEGACY_ACTIVE = 'Y'
                        THEN 'LEGACY'
                    ELSE 'NEW'
                END AS LIMIT_RULE_APPLIED,
                
                CASE
                    WHEN B.CAREER NOT IN ('GR','PR')
                        THEN NULL

                    WHEN NVL(B.KSU_LEGACY_ACTIVE, 'N')
                       <>
                         CASE
                             WHEN LL.LOAN_LIMIT_EXCEPTION_FLG = 'Y'
                                 THEN 'Y'
                             ELSE 'N'
                         END
                        THEN 'Y'

                    ELSE 'N'
                END AS KSU_NSLDS_LEGACY_MISMATCH,

                CASE
                    WHEN LL.PIDM IS NULL THEN 'N'
                    ELSE 'Y'
                END AS RCRLDS4_RECORD_FOUND, 

                NVL(LL.OLD_LIFETIME_USED, 0) AS OLD_LIFETIME_USED,

                NVL(LL.OLD_LIFETIME_SUB_USED, 0) AS OLD_LIFETIME_SUB_USED,

                NVL(LL.OLD_LIFETIME_UNSUB_USED, 0) AS OLD_LIFETIME_UNSUB_USED,

                LL.INFC_CODE_USED,
                LL.SEQ_NO_USED,

                NVL(AL.AGG_TOTAL_LIMIT, 0) AS AGG_TOTAL_LIMIT,

                NVL(AL.AGG_SUB_LIMIT, 0)  AS AGG_SUB_LIMIT,
                NVL(LL.UG_SUB_TOTAL, 0)   AS UG_SUB_TOTAL,
                NVL(LL.UG_UNSUB_TOTAL, 0) AS UG_UNSUB_TOTAL,
                NVL(LL.GR_SUB_TOTAL, 0)   AS GR_SUB_TOTAL,
                NVL(LL.GR_UNSUB_TOTAL, 0) AS GR_UNSUB_TOTAL,

                LL.CURRENT_AGG_COMB_TOTAL,
                FV.FAH_TOTAL_AGG_USED,
                
                CASE
                    WHEN L.CAREER IS NULL THEN 'N'
                    ELSE 'Y'
                END AS ANNUAL_LIMIT_FOUND,

                CASE
                    WHEN FV.PIDM IS NULL
                        THEN NULL

                    WHEN ROUND(NVL(FV.FAH_TOTAL_AGG_USED, 0), 2)
                       <> ROUND(NVL(LL.CURRENT_AGG_COMB_TOTAL, 0), 2)
                        THEN 'Y'

                    ELSE 'N'
                END AS FAH_CURRENT_AGG_MISMATCH,

                /*
                   Historical populated FAH fields - VIEW ONLY.
                   Never referenced by the eligibility calculations.
                */
                FV.FAH_UG_COMB_TOTAL,
                FV.FAH_UG_SUB_TOTAL,
                FV.FAH_UG_UNSUB_TOTAL,
                FV.FAH_UG_UNALLOC_CONS_TOTAL,

                FV.FAH_GR_COMB_TOTAL,
                FV.FAH_GR_SUB_TOTAL,
                FV.FAH_GR_UNSUB_TOTAL,
                FV.FAH_GR_UNALLOC_CONS_TOTAL,

                FV.FAH_NEW_GRAD_AGG_TOTAL,

                FV.FAH_INFC_CODE_USED,
                FV.FAH_SEQ_NO_USED,
                FV.FAH_CURR_REC_USED

            FROM OFA_CALC B

            LEFT JOIN LIFETIME_LOANS LL
              ON LL.PIDM = B.PIDM
            
            LEFT JOIN FAH_AGG_HISTORY_VIEW FV
              ON FV.PIDM = B.PIDM

            LEFT JOIN ANNUAL_LIMITS L
              ON L.CAREER = B.CAREER
             AND L.DEPENDENCY_BUCKET = B.DEPENDENCY_BUCKET
             AND L.GRADE_BUCKET = B.GRADE_BUCKET
             AND L.LIMIT_RULE =
                    CASE
                        WHEN B.CAREER = 'UG'
                            THEN 'ALL'

                        WHEN B.KSU_LEGACY_ACTIVE = 'Y'
                            THEN 'LEGACY'

                        ELSE 'NEW'
                    END

            LEFT JOIN AGG_LIMITS AL
              ON AL.CAREER = B.CAREER
             AND AL.DEPENDENCY_BUCKET = B.DEPENDENCY_BUCKET

             AND AL.LIMIT_RULE =
                    CASE
                        WHEN B.CAREER = 'UG'
                            THEN 'ALL'
                        WHEN B.KSU_LEGACY_ACTIVE = 'Y'
                            THEN 'LEGACY'
                        ELSE 'NEW'
                    END

             AND AL.AGG_BUCKET =
                    CASE
                        WHEN B.CAREER = 'UG'
                            THEN 'ANY'
                        WHEN B.KSU_LEGACY_ACTIVE = 'Y'
                            THEN 'ANY'
                        ELSE NVL(B.GRPR_LIMIT_LEVEL, 'UNKNOWN')
                    END
        ),

    CALC AS (
            SELECT
                CB.*,

                /*
                   Loan-period portion FIRST.
                */
                ROUND(
                    CB.STANDARD_ANNUAL_LIMIT
                    * CB.LOAN_PERIOD_FACTOR,
                    2
                ) AS PERIOD_TOTAL_LIMIT,

                ROUND(
                    CB.STANDARD_SUB_LIMIT
                    * CB.LOAN_PERIOD_FACTOR,
                    2
                ) AS PERIOD_SUB_LIMIT,

                /*
                   Remaining room under the applicable
                   program-level aggregate.
                */
                GREATEST(
                    CB.AGG_TOTAL_LIMIT
                    - CB.LIFETIME_USED,
                    0
                ) AS PROGRAM_AGG_REMAINING,

                /*
                   $257,500 lifetime maximum.

                   Do NOT apply during the GR/PR interim exception.
                */
                CASE
                    WHEN CB.CAREER IN ('GR','PR')
                     AND CB.KSU_LEGACY_ACTIVE = 'Y'
                        THEN NULL

                    ELSE GREATEST(
                             257500
                             - NVL(CB.LIFEMAX_LOAN_TOTAL, 0),
                             0
                         )
                END AS LIFETIME_MAX_REMAINING,

                /*
                   Final aggregate room available BEFORE SOR.

                   Legacy GR/PR:
                     old aggregate only

                   Everyone else:
                     lesser of program aggregate remaining
                     and $257,500 lifetime remaining
                */
                CASE
                    /*
                       If we do not have an NSLDS/RCRLDS4 record,
                       do not assume the borrower has borrowed $0.
                    */
                    WHEN CB.RCRLDS4_RECORD_FOUND = 'N'
                        THEN 0

                    /*
                       Interim / legacy borrower:
                       $257,500 limit does not apply during
                       the exception period.
                    */
                    WHEN CB.CAREER IN ('GR','PR')
                     AND CB.KSU_LEGACY_ACTIVE = 'Y'
                        THEN GREATEST(
                                 CB.AGG_TOTAL_LIMIT
                                 - CB.LIFETIME_USED,
                                 0
                             )

                    /*
                       New-limit borrower:
                       apply BOTH applicable aggregate and
                       overall lifetime maximum.
                    */
                    ELSE LEAST(
                             GREATEST(
                                 CB.AGG_TOTAL_LIMIT
                                 - CB.LIFETIME_USED,
                                 0
                             ),
                             GREATEST(
                                 257500
                                 - NVL(CB.LIFEMAX_LOAN_TOTAL, 0),
                                 0
                             )
                         )
                END AS AGG_TOTAL_REMAINING,

                GREATEST(
                    CB.AGG_SUB_LIMIT
                    - CB.LIFETIME_SUB_USED,
                    0
                ) AS AGG_SUB_REMAINING

            FROM CALC_BASE CB
        ),

    PRE_SOR AS (
        SELECT
            C.*,

            /*
               Step 1:
               Determine total Direct Loan eligibility BEFORE SOR
               and BEFORE aggregate reduction.
            */
            GREATEST(
                0,
                LEAST(
                    C.PERIOD_TOTAL_LIMIT,
                    C.COA_MINUS_OTHER_AID
                )
            ) AS PRE_SOR_TOTAL_BEFORE_AGG,

            /*
               Subsidized eligibility is additionally limited by need.
            */
            GREATEST(
                0,
                LEAST(
                    C.PERIOD_SUB_LIMIT,
                    C.COA_MINUS_SAI_MINUS_OTHER_AID,

                    /* Subsidized cannot exceed total eligibility */
                    C.PERIOD_TOTAL_LIMIT,
                    C.COA_MINUS_OTHER_AID
                )
            ) AS PRE_SOR_SUB_BEFORE_AGG

        FROM CALC C
    ),

    RECOMMENDED AS (
            SELECT
                P.*,

                /*
                   Apply aggregate/lifetime remaining amount BEFORE SOR.
                */
                GREATEST(
                    0,
                    LEAST(
                        P.PRE_SOR_TOTAL_BEFORE_AGG,
                        P.AGG_TOTAL_REMAINING
                    )
                ) AS PRE_SOR_TOTAL_AFTER_AGG,

                GREATEST(
                    0,
                    LEAST(
                        P.PRE_SOR_SUB_BEFORE_AGG,
                        P.AGG_SUB_REMAINING,
                        P.AGG_TOTAL_REMAINING
                    )
                ) AS PRE_SOR_SUB_AFTER_AGG,

                /*
                   =====================================================
                   TOTAL DIRECT LOAN LIMITING FACTOR
                   =====================================================
                */
                CASE
                    /*
                       No room remains under COA after OFA.
                       Student has no additional total DL eligibility.
                    */
                    WHEN NVL(P.TOTAL_DL_COA_ROOM, 0) <= 0
                        THEN 'COA / OFA - NO TOTAL DL ELIGIBILITY'

                    /*
                       Aggregate/lifetime room is the lowest total limit.
                    */
                    WHEN P.AGG_TOTAL_REMAINING
                         <= LEAST(
                                P.PERIOD_TOTAL_LIMIT,
                                P.TOTAL_DL_COA_ROOM
                            )
                        THEN 'AGGREGATE / LIFETIME LIMIT'

                    /*
                       COA minus OFA is lower than the period-adjusted
                       annual limit.
                    */
                    WHEN P.TOTAL_DL_COA_ROOM
                         <= P.PERIOD_TOTAL_LIMIT
                        THEN 'COA / OFA LIMIT'

                    ELSE
                        'STANDARD TOTAL LIMIT/LOAN PERIOD FACTOR'

                END AS LOAN_PERIOD_LIMITING_FACTOR,

                /*
                   =====================================================
                   SUBSIDIZED LOAN LIMITING FACTOR
                   =====================================================
                */
                CASE
                    /*
                       COA - SAI - adjusted OFA leaves no need.
                    */
                    WHEN NVL(P.SUBSIDIZED_NEED, 0) <= 0
                        THEN 'COA - SAI - OFA = NO SUB ELIGIBILITY'

                    /*
                       Subsidized aggregate room is the lowest amount.
                    */
                    WHEN P.AGG_SUB_REMAINING
                         <= LEAST(
                                P.SUBSIDIZED_NEED,
                                P.PERIOD_SUB_LIMIT,
                                P.PERIOD_TOTAL_LIMIT,
                                P.TOTAL_DL_COA_ROOM,
                                P.AGG_TOTAL_REMAINING
                            )
                        THEN 'SUBSIDIZED AGGREGATE LIMIT'

                    /*
                       Overall total aggregate/lifetime room constrains Sub.
                    */
                    WHEN P.AGG_TOTAL_REMAINING
                         <= LEAST(
                                P.SUBSIDIZED_NEED,
                                P.PERIOD_SUB_LIMIT,
                                P.PERIOD_TOTAL_LIMIT,
                                P.TOTAL_DL_COA_ROOM
                            )
                        THEN 'TOTAL AGGREGATE / LIFETIME LIMIT'

                    /*
                       COA - SAI - OFA is the lowest Subsidized amount.
                    */
                    WHEN P.SUBSIDIZED_NEED
                         <= LEAST(
                                P.PERIOD_SUB_LIMIT,
                                P.PERIOD_TOTAL_LIMIT,
                                P.TOTAL_DL_COA_ROOM
                            )
                        THEN 'COA - SAI - OFA / SUB NEED LIMIT'

                    /*
                       Period-adjusted Subsidized annual limit.
                    */
                    WHEN P.PERIOD_SUB_LIMIT
                         <= LEAST(
                                P.PERIOD_TOTAL_LIMIT,
                                P.TOTAL_DL_COA_ROOM
                            )
                        THEN 'STANDARD SUB LIMIT/LOAN PERIOD FACTOR'

                    /*
                       Total annual DL limit constrains Subsidized.
                    */
                    WHEN P.PERIOD_TOTAL_LIMIT
                         <= P.TOTAL_DL_COA_ROOM
                        THEN 'TOTAL ANNUAL LIMIT/LOAN PERIOD FACTOR'

                    ELSE
                        'COA / OFA LIMIT'

                END AS SUB_LIMITING_FACTOR

            FROM PRE_SOR P
        ),

    FINAL_CALC AS (
        SELECT
            R.*,

            ROUND(
                R.STANDARD_ANNUAL_LIMIT,
                2
            ) AS INITIAL_MAX_ANNUAL_LIMIT,

            ROUND(
                R.PERIOD_TOTAL_LIMIT,
                2
            ) AS PERIOD_FACTOR_LIMIT,

            /*
               Informational:
               What the period limit would be after SOR
               without the other eligibility caps.
            */
            ROUND(
                R.PERIOD_TOTAL_LIMIT
                * R.SOR_PCT,
                2
            ) AS SOR_ANNUAL_LIMIT,

            /*
               Amount before aggregate/lifetime reduction,
               but after COA/OFA rules and SOR.
            */
            ROUND(
                R.PRE_SOR_TOTAL_BEFORE_AGG
                * R.SOR_PCT,
                2
            ) AS FINAL_ALLOWABLE_LOAN_PRE_NEED,

            ROUND(
                R.PRE_SOR_SUB_BEFORE_AGG
                * R.SOR_PCT,
                2
            ) AS MAXIMUM_SUBSIDIZED_ELIGIBILITY,

            ROUND(
                R.PRE_SOR_TOTAL_BEFORE_AGG
                * R.SOR_PCT,
                2
            ) AS RECOMMENDED_TOTAL_BEFORE_AGG,

            ROUND(
                R.PRE_SOR_SUB_BEFORE_AGG
                * R.SOR_PCT,
                2
            ) AS RECOMMENDED_SUB_BEFORE_AGG,

            /*
               FINAL annual/loan-period eligibility after:
                 period factor
                 COA / OFA
                 subsidized need
                 aggregate/lifetime
                 SOR
            */
            ROUND(
                R.PRE_SOR_TOTAL_AFTER_AGG
                * R.SOR_PCT,
                2
            ) AS FINAL_ALLOWABLE_LOAN,

            ROUND(
                R.PRE_SOR_SUB_AFTER_AGG
                * R.SOR_PCT,
                2
            ) AS RECOMMENDED_SUBSIDIZED,

            GREATEST(
                0,
                ROUND(
                    (R.PRE_SOR_TOTAL_AFTER_AGG * R.SOR_PCT)
                    -
                    (R.PRE_SOR_SUB_AFTER_AGG * R.SOR_PCT),
                    2
                )
            ) AS RECOMMENDED_UNSUBSIDIZED

        FROM RECOMMENDED R
    ),

    REMAINING_ELIGIBILITY_BASE AS (
        SELECT
            F.*,

            ROUND(
                NVL(F.CURRENT_AY_SUBSIDIZED_ALREADY_OFFERED, 0)
                +
                NVL(F.CURRENT_AY_UNSUBSIDIZED_ALREADY_OFFERED, 0),
                2
            ) AS CURRENT_TOTAL_OFFERED,

            ROUND(
                NVL(F.CURRENT_AY_SUB_PAID, 0)
                +
                NVL(F.CURRENT_AY_UNSUB_PAID, 0),
                2
            ) AS PAID_TO_DATE_TOTAL,

            /*
               Amount currently offered but not already paid.
            */
            GREATEST(
                ROUND(
                    NVL(F.CURRENT_AY_SUBSIDIZED_ALREADY_OFFERED, 0)
                    -
                    NVL(F.CURRENT_AY_SUB_PAID, 0),
                    2
                ),
                0
            ) AS UNDISBURSED_SUB_OFFER,

            GREATEST(
                ROUND(
                    NVL(F.CURRENT_AY_UNSUBSIDIZED_ALREADY_OFFERED, 0)
                    -
                    NVL(F.CURRENT_AY_UNSUB_PAID, 0),
                    2
                ),
                0
            ) AS UNDISBURSED_UNSUB_OFFER,

            GREATEST(
                ROUND(
                    NVL(F.CURRENT_AY_SUBSIDIZED_ALREADY_OFFERED, 0)
                    +
                    NVL(F.CURRENT_AY_UNSUBSIDIZED_ALREADY_OFFERED, 0)
                    -
                    NVL(F.CURRENT_AY_SUB_PAID, 0)
                    -
                    NVL(F.CURRENT_AY_UNSUB_PAID, 0),
                    2
                ),
                0
            ) AS UNDISBURSED_CURRENT_OFFER,

            /*
               New FAQ treatment:
               determine revised annual eligibility, then subtract
               amounts already disbursed.
            */
            GREATEST(
                ROUND(
                    (F.RECOMMENDED_SUBSIDIZED
                     + F.RECOMMENDED_UNSUBSIDIZED)
                    -
                    (NVL(F.CURRENT_AY_SUB_PAID, 0)
                     + NVL(F.CURRENT_AY_UNSUB_PAID, 0)),
                    2
                ),
                0
            ) AS REMAINING_TOTAL_ELIGIBILITY,

            GREATEST(
                ROUND(
                    F.RECOMMENDED_SUBSIDIZED
                    -
                    NVL(F.CURRENT_AY_SUB_PAID, 0),
                    2
                ),
                0
            ) AS REMAINING_SUB_ELIGIBILITY_RAW

        FROM FINAL_CALC F
    ),

    REMAINING_ELIGIBILITY AS (
        SELECT
            R.*,

            /*
               Remaining subsidized cannot exceed remaining total.
            */
            LEAST(
                R.REMAINING_SUB_ELIGIBILITY_RAW,
                R.REMAINING_TOTAL_ELIGIBILITY
            ) AS REMAINING_SUB_ELIGIBILITY,

            /*
               Whatever remains after Subsidized can be Unsubsidized.
            */
            GREATEST(
                R.REMAINING_TOTAL_ELIGIBILITY
                -
                LEAST(
                    R.REMAINING_SUB_ELIGIBILITY_RAW,
                    R.REMAINING_TOTAL_ELIGIBILITY
                ),
                0
            ) AS REMAINING_UNSUB_ELIGIBILITY

        FROM REMAINING_ELIGIBILITY_BASE R
    ),

    RECONCILED_BASE AS (
        SELECT /*+ MATERIALIZE */
            F.*,

            CASE
                WHEN :TERM = :SMR_TERM
                 AND F.AID_PERIOD IN
                     ('SUMMER', 'SMRFAL', 'SMRSPR', 'SMFLSP')
                    THEN 'Y'

                WHEN :TERM = :FAL_TERM
                 AND F.AID_PERIOD IN
                     ('FALL', 'SMRFAL', 'FA/SPR', 'SMFLSP')
                    THEN 'Y'

                WHEN :TERM = :SPR_TERM
                 AND F.AID_PERIOD IN
                     ('SPRING', 'SMRSPR', 'FA/SPR', 'SMFLSP')
                    THEN 'Y'

                ELSE 'N'
            END AS TERM_INCLUDED_IN_AID_PERIOD,
                        
            CASE
                WHEN F.AID_PERIOD NOT IN
                     ('SUMMER', 'SMRFAL', 'SMRSPR', 'SMFLSP')
                    THEN 'N/A'

                /*
                   While processing Summer itself, Summer must remain
                   available in the allocation.
                */
                WHEN :TERM = :SMR_TERM
                    THEN 'Y'

                /*
                   Fall/Spring review:
                   actual Summer loan payment proves Summer was used.
                */
                WHEN NVL(F.SMR_SUB_PAID, 0)
                   + NVL(F.SMR_UNSUB_PAID, 0) > 0
                    THEN 'Y'

                /*
                   No Summer Direct Loan was actually received.
                */
                ELSE 'N'

            END AS SUMMER_INCLUDED_IN_TERM_SPLIT,

            
            CASE
                /*
                   Student must be half time in the current term.
                */
                WHEN F.HALF_TIME_ELIGIBLE = 'N'
                    THEN 0

                /*
                   Single-term aid period.
                */
                WHEN F.AID_PERIOD IN ('SUMMER', 'FALL', 'SPRING')
                    THEN 1

                /*
                   Fall/Spring aid period always splits between two terms.
                */
                WHEN F.AID_PERIOD = 'FA/SPR'
                    THEN .5

                /*
                   Summer/Fall or Summer/Spring:

                   When reviewing Fall/Spring, if no Summer Direct Loan
                   was actually paid, Summer does not consume part of
                   the annual eligibility. Give the remaining term 100%.
                */
                WHEN F.AID_PERIOD IN ('SMRFAL', 'SMRSPR')
                 AND :TERM IN (:FAL_TERM, :SPR_TERM)
                 AND NVL(F.SMR_SUB_PAID, 0) = 0
                 AND NVL(F.SMR_UNSUB_PAID, 0) = 0
                    THEN 1

                /*
                   Summer/Fall/Spring:

                   When reviewing Fall or Spring, if no Summer Direct
                   Loan was paid, divide the annual eligibility between
                   Fall and Spring only.
                */
                WHEN F.AID_PERIOD = 'SMFLSP'
                 AND :TERM IN (:FAL_TERM, :SPR_TERM)
                 AND NVL(F.SMR_SUB_PAID, 0) = 0
                 AND NVL(F.SMR_UNSUB_PAID, 0) = 0
                    THEN .5

                /*
                   Normal Summer/Fall or Summer/Spring allocation when
                   Summer actually participated.
                */
                WHEN F.AID_PERIOD IN ('SMRFAL', 'SMRSPR')
                    THEN .5

                /*
                   Normal three-term Summer/Fall/Spring allocation.
                */
                WHEN F.AID_PERIOD = 'SMFLSP'
                 AND :TERM = :SMR_TERM
                    THEN .3334

                WHEN F.AID_PERIOD = 'SMFLSP'
                 AND :TERM IN (:FAL_TERM, :SPR_TERM)
                    THEN .3333

                ELSE 0

            END AS TERM_SPLIT_PCT
            
        FROM REMAINING_ELIGIBILITY F
    ),

    RECONCILED_AMOUNT AS (
        SELECT /*+ MATERIALIZE */
            F.*,

            ROUND(
                F.RECOMMENDED_SUBSIDIZED
                + F.RECOMMENDED_UNSUBSIDIZED,
                2
            ) AS RECOMMENDED_TOTAL,

            GREATEST(
                ROUND(
                    NVL(F.TERM_SUB_OFFER, 0)
                    +
                    NVL(F.TERM_UNSUB_OFFER, 0)
                    -
                    NVL(F.TERM_SUB_PAID, 0)
                    -
                    NVL(F.TERM_UNSUB_PAID, 0),
                    2
                ),
                0
            ) AS TERM_UNDISBURSED_OFFER,

            /*
               Recommended ADDITIONAL Subsidized amount that could
               still be disbursed in the current term.

               It is capped by:
                 1. current-term half-time status
                 2. term split target
                 3. amount already paid in the term
                 4. annual remaining eligibility
            */
            CASE
                WHEN NOT (
                        (:TERM = :SMR_TERM
                         AND F.AID_PERIOD IN
                             ('SUMMER','SMRFAL','SMRSPR','SMFLSP'))

                     OR (:TERM = :FAL_TERM
                         AND F.AID_PERIOD IN
                             ('FALL','SMRFAL','FA/SPR','SMFLSP'))

                     OR (:TERM = :SPR_TERM
                         AND F.AID_PERIOD IN
                             ('SPRING','SMRSPR','FA/SPR','SMFLSP'))
                )
                    THEN 0

                WHEN F.HALF_TIME_ELIGIBLE = 'N'
                    THEN 0

                ELSE LEAST(
                    F.REMAINING_SUB_ELIGIBILITY,

                    GREATEST(
                        (
                            CASE
                                WHEN F.AID_PERIOD = 'SMFLSP'
                                     AND F.SUMMER_INCLUDED_IN_TERM_SPLIT = 'Y'
                                     AND :TERM = :SMR_TERM
                                    THEN
                                        ROUND(F.RECOMMENDED_SUBSIDIZED, 0)
                                        -
                                        (
                                            FLOOR(
                                                ROUND(
                                                    F.RECOMMENDED_SUBSIDIZED,
                                                    0
                                                ) / 3
                                            ) * 2
                                        )

                                WHEN F.AID_PERIOD = 'SMFLSP'
                                     AND F.SUMMER_INCLUDED_IN_TERM_SPLIT = 'Y'
                                     AND :TERM IN (:FAL_TERM, :SPR_TERM)
                                    THEN
                                        FLOOR(
                                            ROUND(
                                                F.RECOMMENDED_SUBSIDIZED,
                                                0
                                            ) / 3
                                        )

                                ELSE
                                    ROUND(
                                        F.RECOMMENDED_SUBSIDIZED
                                        * F.TERM_SPLIT_PCT,
                                        0
                                    )
                            END
                        )
                        -
                        NVL(F.TERM_SUB_PAID, 0),
                        0
                    )
                )
            END AS RECOMMENDED_TERM_SUBSIDIZED,

            CASE
                WHEN NOT (
                        (:TERM = :SMR_TERM
                         AND F.AID_PERIOD IN
                             ('SUMMER','SMRFAL','SMRSPR','SMFLSP'))

                     OR (:TERM = :FAL_TERM
                         AND F.AID_PERIOD IN
                             ('FALL','SMRFAL','FA/SPR','SMFLSP'))

                     OR (:TERM = :SPR_TERM
                         AND F.AID_PERIOD IN
                             ('SPRING','SMRSPR','FA/SPR','SMFLSP'))
                )
                    THEN 0

                WHEN F.HALF_TIME_ELIGIBLE = 'N'
                    THEN 0

                ELSE LEAST(
                    F.REMAINING_UNSUB_ELIGIBILITY,

                    GREATEST(
                        (
                            CASE
                                WHEN F.AID_PERIOD = 'SMFLSP'
                                     AND F.SUMMER_INCLUDED_IN_TERM_SPLIT = 'Y'
                                     AND :TERM = :SMR_TERM
                                    THEN
                                        ROUND(
                                            F.RECOMMENDED_UNSUBSIDIZED,
                                            0
                                        )
                                        -
                                        (
                                            FLOOR(
                                                ROUND(
                                                    F.RECOMMENDED_UNSUBSIDIZED,
                                                    0
                                                ) / 3
                                            ) * 2
                                        )

                                WHEN F.AID_PERIOD = 'SMFLSP'
                                     AND F.SUMMER_INCLUDED_IN_TERM_SPLIT = 'Y'
                                     AND :TERM IN (:FAL_TERM, :SPR_TERM)
                                    THEN
                                        FLOOR(
                                            ROUND(
                                                F.RECOMMENDED_UNSUBSIDIZED,
                                                0
                                            ) / 3
                                        )

                                ELSE
                                    ROUND(
                                        F.RECOMMENDED_UNSUBSIDIZED
                                        * F.TERM_SPLIT_PCT,
                                        0
                                    )
                            END
                        )
                        -
                        NVL(F.TERM_UNSUB_PAID, 0),
                        0
                    )
                )
            END AS RECOMMENDED_TERM_UNSUBSIDIZED,
            
            GREATEST(
                ROUND(
                    NVL(F.TERM_SUB_OFFER, 0)
                    - NVL(F.TERM_SUB_PAID, 0),
                    2
                ),
                0
            ) AS TERM_UNDISBURSED_SUB_OFFER,

            GREATEST(
                ROUND(
                    NVL(F.TERM_UNSUB_OFFER, 0)
                    - NVL(F.TERM_UNSUB_PAID, 0),
                    2
                ),
                0
            ) AS TERM_UNDISBURSED_UNSUB_OFFER

        FROM RECONCILED_BASE F
    ),
    
    TERM_TOTAL_CALC AS (
            SELECT
                R.*,

                NVL(R.RECOMMENDED_TERM_SUBSIDIZED, 0)
              + NVL(R.RECOMMENDED_TERM_UNSUBSIDIZED, 0)
                    AS RECOMMENDED_TERM_TOTAL,

                ROUND(
                    NVL(R.RECOMMENDED_TERM_SUBSIDIZED, 0)
                    - NVL(R.TERM_UNDISBURSED_SUB_OFFER, 0),
                    2
                ) AS TERM_SUB_DIFF,

                ROUND(
                    NVL(R.RECOMMENDED_TERM_UNSUBSIDIZED, 0)
                    - NVL(R.TERM_UNDISBURSED_UNSUB_OFFER, 0),
                    2
                ) AS TERM_UNSUB_DIFF,

                ROUND(
                    (
                        NVL(R.RECOMMENDED_TERM_SUBSIDIZED, 0)
                        + NVL(R.RECOMMENDED_TERM_UNSUBSIDIZED, 0)
                    )
                    - NVL(R.TERM_UNDISBURSED_OFFER, 0),
                    2
                ) AS TERM_TOTAL_DIFF

            FROM RECONCILED_AMOUNT R
        ),

            RECONCILED AS (
            SELECT
                R.*,

            CASE

                WHEN R.RCRLDS4_RECORD_FOUND = 'N'
                    THEN 'REVIEW - NSLDS LOAN HISTORY NOT AVAILABLE'

                WHEN R.ANNUAL_LIMIT_FOUND = 'N'
                    THEN 'REVIEW - ANNUAL LOAN LIMIT NOT DETERMINED'

                WHEN R.CAREER IN ('GR','PR')
                 AND NVL(R.KSU_LEGACY_ACTIVE, 'N') <> 'Y'
                 AND NVL(R.GRPR_LIMIT_LEVEL, 'X')
                        NOT IN ('A','B','C','D','E','F')
                    THEN 'REVIEW - GR/PR LOAN LEVEL NOT DETERMINED'

                WHEN R.TERM_INCLUDED_IN_AID_PERIOD <> 'Y'
                    THEN 'CURRENT TERM NOT IN AID PERIOD'

                WHEN R.HALF_TIME_ELIGIBLE = 'N'
                    THEN 'BELOW HALF TIME - NO CURRENT TERM DL ELIGIBILITY'

                WHEN NVL(R.TOTAL_DL_COA_ROOM, 0) <= 0
                    THEN 'COA / OFA - NO DIRECT LOAN ELIGIBILITY'

                WHEN NVL(R.AGG_TOTAL_REMAINING, 0) <= 0
                    THEN 'AGGREGATE / LIFETIME - NO DIRECT LOAN ELIGIBILITY'

                WHEN NVL(R.SOR_PCT, 0) <= 0
                    THEN 'SOR / ENROLLMENT INTENSITY - NO DIRECT LOAN ELIGIBILITY'

                WHEN R.SOR_PCT < 1
                    THEN
                        'SOR '
                        || TO_CHAR(
                               ROUND(R.SOR_PCT * 100, 0),
                               'FM990'
                           )
                        || '% APPLIED TO '
                        || R.LOAN_PERIOD_LIMITING_FACTOR

                ELSE R.LOAN_PERIOD_LIMITING_FACTOR

            END AS DIRECT_LOAN_LIMITING_FACTOR,

            CASE

                WHEN R.RCRLDS4_RECORD_FOUND = 'N'
                    THEN 'REVIEW'

                WHEN R.ANNUAL_LIMIT_FOUND = 'N'
                    THEN 'REVIEW'

                WHEN R.CAREER IN ('GR','PR')
                 AND NVL(R.KSU_LEGACY_ACTIVE, 'N') <> 'Y'
                 AND NVL(R.GRPR_LIMIT_LEVEL, 'X')
                        NOT IN ('A','B','C','D','E','F')
                    THEN 'REVIEW'

                WHEN R.TERM_INCLUDED_IN_AID_PERIOD = 'Y'
                 AND R.HALF_TIME_ELIGIBLE = 'N'
                 AND R.TERM_UNDISBURSED_OFFER > 0
                    THEN 'DECREASE'

                WHEN R.RECOMMENDED_TERM_TOTAL = 0
                 AND R.TERM_UNDISBURSED_OFFER > 0
                    THEN 'DECREASE'

                WHEN R.TERM_UNDISBURSED_OFFER = 0
                 AND R.RECOMMENDED_TERM_TOTAL > 0
                    THEN 'OFFER_NEW'

                WHEN R.TERM_TOTAL_DIFF > 0
                    THEN 'INCREASE'

                WHEN R.TERM_TOTAL_DIFF < 0
                    THEN 'DECREASE'

                WHEN R.TERM_TOTAL_DIFF = 0
                 AND (
                        R.TERM_SUB_DIFF <> 0
                     OR R.TERM_UNSUB_DIFF <> 0
                     )
                    THEN 'ADJUST_SUB_UNSUB'

                ELSE 'NO_CHANGE'

            END AS COUNSELOR_ACTION

            FROM TERM_TOTAL_CALC R
        )

    SELECT
        COUNSELOR_ACTION,
        CASE
            WHEN RCRLDS4_RECORD_FOUND = 'N'
                THEN
                'REVIEW - NO CURRENT RCRLDS4/NSLDS LOAN HISTORY RECORD FOUND; MANUAL REVIEW REQUIRED'
            WHEN PAID_TO_DATE_TOTAL > RECOMMENDED_TOTAL
             AND UNDISBURSED_CURRENT_OFFER = 0
                THEN
                'REVIEW - PAID TO DATE EXCEEDS RECALCULATED LIMIT; NO FUTURE AMOUNT REMAINS'
            WHEN TERM_INCLUDED_IN_AID_PERIOD = 'Y'
             AND HALF_TIME_ELIGIBLE = 'N'
             AND TERM_UNDISBURSED_OFFER > 0
                THEN
                'HOLD/DECREASE - CURRENT TERM IS BELOW HALF TIME; REDUCE/CANCEL FUTURE DISBURSEMENT'
            WHEN RECOMMENDED_TOTAL_BEFORE_AGG > RECOMMENDED_TOTAL
                THEN
                'REVIEW - AGGREGATE LIMIT REDUCED ELIGIBILITY'
            WHEN COUNSELOR_ACTION = 'DECREASE'
                THEN
                'HOLD/REVIEW - UNDISTRIBUTED OFFER EXCEEDS REMAINING ELIGIBILITY'
            WHEN COUNSELOR_ACTION = 'ADJUST_SUB_UNSUB'
                THEN
                'REVIEW - FUTURE SUB/UNSUB MIX REQUIRES ADJUSTMENT'
            WHEN COUNSELOR_ACTION = 'INCREASE'
                THEN
                'REVIEW - ADDITIONAL ELIGIBILITY POSSIBLE; VERIFY BORROWER REQUEST BEFORE INCREASING'
            WHEN COUNSELOR_ACTION = 'OFFER_NEW'
                THEN
               'REVIEW - ADDITIONAL LOAN ELIGIBILITY POSSIBLE; VERIFY BORROWER REQUEST'
            WHEN KSU_NSLDS_LEGACY_MISMATCH = 'Y'
                THEN
                'REVIEW - KSU LEGACY DETERMINATION DIFFERS FROM NSLDS EXCEPTION FLAG'              
            WHEN LOAN_LIMIT_EXCEPTION_FLG IS NOT NULL
             AND LOAN_LIMIT_EXCEPTION_FLG <> 'N'
                THEN
                'REVIEW - NSLDS LOAN LIMIT EXCEPTION FLAG'         
            WHEN LIFEMAX_LOAN_LIMIT_FLG IS NOT NULL
             AND LIFEMAX_LOAN_LIMIT_FLG <> 'N'
                THEN
                'REVIEW - NSLDS LIFETIME MAXIMUM LOAN LIMIT FLAG'
            WHEN ANNUAL_LIMIT_FOUND = 'N'
             AND CAREER IS NULL
                THEN
                'REVIEW - STUDENT CAREER/LEVEL COULD NOT BE DETERMINED'
            WHEN ANNUAL_LIMIT_FOUND = 'N'
             AND CAREER = 'UG'
             AND GRADE_BUCKET IS NULL
                THEN
                'REVIEW - UNDERGRADUATE GRADE LEVEL NOT AVAILABLE'
            WHEN ANNUAL_LIMIT_FOUND = 'N'
             AND CAREER = 'UG'
                THEN
                'REVIEW - UNDERGRADUATE GRADE LEVEL DOES NOT MATCH A LOAN LIMIT'
            WHEN CAREER = 'GR'
             AND GR_COMB_LOAN_LIMIT_FLG IS NOT NULL
             AND GR_COMB_LOAN_LIMIT_FLG <> 'N'
                THEN
                'REVIEW - NSLDS GRADUATE COMBINED LOAN LIMIT FLAG'
            WHEN CAREER = 'PR'
             AND PR_COMB_LOAN_LIMIT_FLG IS NOT NULL
             AND PR_COMB_LOAN_LIMIT_FLG <> 'N'
                THEN
                'REVIEW - NSLDS PROFESSIONAL COMBINED LOAN LIMIT FLAG'
            ELSE
                'NO ACTION'
        END AS REVIEW_REASON,
        SPRIDEN_ID,
        SPRIDEN_LAST_NAME,
        SPRIDEN_FIRST_NAME,
        AIDY_CODE,
        PCKG_COMP_DATE,
        PACKAGING_GROUP,
        TRACKING_GROUP,
        AID_PERIOD,
        CAREER,
        STUDENT_TYPE,
        PROGRAM,
        PROGRAM_TERM,
        DEPENDENCY_STATUS,
        GRADE_LEVEL,
        YEAR_EXPECTED_ENROLLMENT,

        SMR_REGISTERED_HOURS,
        FAL_REGISTERED_HOURS,
        SPR_REGISTERED_HOURS,
        FEDAID_HRS_SMR,
        FEDAID_HRS_FAL,
        FEDAID_HRS_SPR,

        SOR_HOURS_SMR,
        SOR_HOURS_SMR_SOURCE,

        SOR_HOURS_FAL,
        SOR_HOURS_FAL_SOURCE,

        SOR_HOURS_SPR,
        SOR_HOURS_SPR_SOURCE,
        HOURS_USED_FOR_SOR,
        HALF_TIME_ELIGIBLE,
        
        TO_CHAR(TERM_SUB_OFFER,'$999,999,999.00') AS TERM_SUB_OFFER,
        TO_CHAR(TERM_UNSUB_OFFER,'$999,999,999.00') AS TERM_UNSUB_OFFER,

        TO_CHAR(TERM_SUB_PAID,'$999,999,999.00') AS TERM_SUB_PAID,
        TO_CHAR(TERM_UNSUB_PAID,'$999,999,999.00') AS TERM_UNSUB_PAID,

        TO_CHAR( PRE_SOR_TOTAL_AFTER_AGG,'$999,999,999.00') AS LOAN_PERIOD_MAX_BEFORE_SOR,

        TO_CHAR(
            CASE
                WHEN RCRLDS4_RECORD_FOUND = 'N'
                    THEN NULL

                WHEN ANNUAL_LIMIT_FOUND = 'N'
                    THEN NULL

                WHEN CAREER IN ('GR','PR')
                 AND NVL(KSU_LEGACY_ACTIVE, 'N') <> 'Y'
                 AND NVL(GRPR_LIMIT_LEVEL, 'X')
                        NOT IN ('A','B','C','D','E','F')
                    THEN NULL

                WHEN TERM_INCLUDED_IN_AID_PERIOD <> 'Y'
                    THEN 0

                WHEN HALF_TIME_ELIGIBLE = 'N'
                    THEN 0

                WHEN NVL(TOTAL_DL_COA_ROOM, 0) <= 0
                    THEN 0

                WHEN NVL(AGG_TOTAL_REMAINING, 0) <= 0
                    THEN 0

                WHEN NVL(SOR_PCT, 0) <= 0
                    THEN 0

                ELSE NVL(RECOMMENDED_TERM_TOTAL, 0)

            END,
            '$999,999,999.00'
        ) AS MAX_CURRENT_TERM_ELIGIBILITY,

        FT_HOURS_FOR_SOR,
        ROUND(SOR_PCT * 100, 0) AS COD_ENROLLMENT_INTENSITY,
        TO_CHAR(
            ROUND(SOR_PCT * 100, 0),
            'FM990'
        ) || '%' AS SOR_PCT,

        TO_CHAR(RECOMMENDED_TERM_SUBSIDIZED,'$999,999,999.00') AS RECOMMENDED_TERM_SUBSIDIZED,
        TO_CHAR(RECOMMENDED_TERM_UNSUBSIDIZED, '$999,999,999.00') AS RECOMMENDED_TERM_UNSUBSIDIZED,
        TO_CHAR(RECOMMENDED_TERM_TOTAL,'$999,999,999.00') AS RECOMMENDED_TERM_TOTAL,
        
        CASE
            WHEN COALESCE(
                     ROBUSDF_VALUE_110,
                     ROBUSDF_VALUE_118,
                     ROBUSDF_VALUE_119,
                     ROBUSDF_VALUE_120
                 ) IS NOT NULL
                THEN 'Y'
            ELSE 'N'
        END AS MANUAL_CALC_ON_FILE,
        DIRECT_LOAN_LIMITING_FACTOR,
        LOAN_PERIOD_LIMITING_FACTOR,
        SUB_LIMITING_FACTOR,
        FEDAID_HRS_SMR,
        TO_CHAR(SMR_SUB_PAID,'$999,999,999.00') AS SMR_SUB_PAID,
        TO_CHAR(SMR_UNSUB_PAID,'$999,999,999.00') AS SMR_UNSUB_PAID,
        SUMMER_INCLUDED_IN_TERM_SPLIT,
        TERM_SPLIT_PCT,  
        TO_CHAR(STANDARD_ANNUAL_LIMIT,'$999,999,990.00') AS STANDARD_ANNUAL_LIMIT,
        TO_CHAR(STANDARD_SUB_LIMIT,'$999,999,990.00') AS STANDARD_SUB_LIMIT,
        TO_CHAR(AGG_TOTAL_LIMIT,'$999,999,999.00') AS AGG_TOTAL_LIMIT,
        TO_CHAR(AGG_SUB_LIMIT,'$999,999,999.00') AS AGG_SUB_LIMIT,

        TO_CHAR(LIFETIME_USED,'$999,999,999.00') AS APPLICABLE_AGG_USED,

        TO_CHAR(LIFETIME_SUB_USED,'$999,999,999.00') AS APPLICABLE_AGG_SUB_USED,

        TO_CHAR(LIFETIME_UNSUB_USED,'$999,999,999.00') AS APPLICABLE_AGG_UNSUB_USED,

        TO_CHAR(LIFEMAX_LOAN_TOTAL, '$999,999,999.00') AS LIFETIME_MAX_USED,

        TO_CHAR(LIFETIME_MAX_REMAINING,'$999,999,999.00') AS LIFETIME_MAX_REMAINING,

        TO_CHAR(AGG_TOTAL_REMAINING, '$999,999,999.00') AS FINAL_AGG_TOTAL_REMAINING,

        TO_CHAR(AGG_SUB_REMAINING, '$999,999,999.00') AS FINAL_AGG_SUB_REMAINING,

        TO_CHAR(FAH_TOTAL_AGG_USED,'$999,999,999.00' ) AS FAH_TOTAL_AGG_USED,

        TO_CHAR(CURRENT_AGG_COMB_TOTAL,'$999,999,999.00') AS CURRENT_AGG_COMB_TOTAL,

        FAH_CURRENT_AGG_MISMATCH,

        TO_CHAR(FAH_UG_COMB_TOTAL,'$999,999,999.00') AS FAH_UG_COMB_TOTAL,

        TO_CHAR(FAH_UG_SUB_TOTAL,'$999,999,999.00') AS FAH_UG_SUB_TOTAL,

        TO_CHAR(FAH_UG_UNSUB_TOTAL,'$999,999,999.00') AS FAH_UG_UNSUB_TOTAL,

        TO_CHAR(FAH_UG_UNALLOC_CONS_TOTAL,'$999,999,999.00') AS FAH_UG_UNALLOC_CONS_TOTAL,

        TO_CHAR(FAH_GR_COMB_TOTAL,'$999,999,999.00') AS FAH_GR_COMB_TOTAL,

        TO_CHAR(FAH_GR_SUB_TOTAL,'$999,999,999.00') AS FAH_GR_SUB_TOTAL,

        TO_CHAR(FAH_GR_UNSUB_TOTAL,'$999,999,999.00') AS FAH_GR_UNSUB_TOTAL,

        TO_CHAR(FAH_GR_UNALLOC_CONS_TOTAL,'$999,999,999.00') AS FAH_GR_UNALLOC_CONS_TOTAL,

        TO_CHAR(FAH_NEW_GRAD_AGG_TOTAL,'$999,999,999.00') AS FAH_NEW_GRAD_AGG_TOTAL,

        FAH_INFC_CODE_USED,
        FAH_SEQ_NO_USED,
        FAH_CURR_REC_USED,
        
        TO_CHAR(LOAN_PERIOD_FACTOR,'FM0.00') AS LOAN_PERIOD_FACTOR,
        TO_CHAR(PERIOD_FACTOR_LIMIT,'$999,999,999.00') AS PERIOD_FACTOR_LIMIT,
        TO_CHAR(SOR_ANNUAL_LIMIT,'$999,999,999.00') AS SOR_ANNUAL_LIMIT,

        TO_CHAR(COA_TOTAL,'$999,999,999.00') AS COA_TOTAL,
        SAI,
        TO_CHAR(ALL_OTHER_AY_AID,'$999,999,999.00') AS ALL_OTHER_AID,
        TO_CHAR(PLUS_OFFERED, '$999,999,999.00') AS AY_PLUS_OFFERED,
        TO_CHAR(COA_MINUS_SAI_MINUS_OTHER_AID,'$999,999,999.00') AS COA_MINUS_SAI_MINUS_OTHER_AID,

        TO_CHAR(NEED_BASED_AY_AID,'$999,999,999.00') AS NEED_BASED_AY_AID,

        TO_CHAR(MERIT_INSTITUTIONAL_AY_AID, '$999,999,999.00') AS MERIT_INSTITUTIONAL_AY_AID,

        TO_CHAR(OTHER_AID_RESOURCES,'$999,999,999.00') AS OTHER_AID_RESOURCES,

        TO_CHAR(FWS_OFFERED,'$999,999,999.00') AS FWS_OFFERED,

        TO_CHAR(TEACH_OFFERED,'$999,999,999.00') AS TEACH_OFFERED,

        TO_CHAR(PRIVATE_LOAN_OFFERED,'$999,999,999.00') AS PRIVATE_LOAN_OFFERED,

        TO_CHAR(PLUS_OFFERED,'$999,999,999.00') AS PLUS_OFFERED,

        TO_CHAR(ALL_OTHER_AY_AID,'$999,999,999.00') AS ALL_OTHER_AY_AID,

        TO_CHAR(SAI_REPLACE_ELIGIBLE_AID,'$999,999,999.00') AS SAI_REPLACE_ELIGIBLE_AID,

        TO_CHAR(SAI_REPLACEMENT_USED,'$999,999,999.00') AS SAI_REPLACEMENT_USED,

        TO_CHAR(OFA_FOR_SUB_NEED,'$999,999,999.00') AS OFA_FOR_SUB_NEED,

        TO_CHAR(SUBSIDIZED_NEED,'$999,999,999.00') AS SUBSIDIZED_NEED,

        TO_CHAR(TOTAL_DL_COA_ROOM,'$999,999,999.00') AS TOTAL_DL_COA_ROOM,

        TO_CHAR(CURRENT_AY_SUBSIDIZED_ALREADY_OFFERED,'$999,999,999.00') AS CURRENT_AY_SUBSIDIZED_ALREADY_OFFERED,
        TO_CHAR(CURRENT_AY_UNSUBSIDIZED_ALREADY_OFFERED,'$999,999,999.00') AS CURRENT_AY_UNSUBSIDIZED_ALREADY_OFFERED,
        TO_CHAR(CURRENT_TOTAL_OFFERED,'$999,999,999.00') AS CURRENT_TOTAL_OFFERED,
        TO_CHAR(CURRENT_AY_SUB_PAID, '$999,999,999.00') AS CURRENT_AY_SUB_PAID,
        TO_CHAR(CURRENT_AY_UNSUB_PAID, '$999,999,999.00') AS CURRENT_AY_UNSUB_PAID,
        TO_CHAR(PAID_TO_DATE_TOTAL,'$999,999,999.00') AS PAID_TO_DATE_TOTAL,
        TO_CHAR(REMAINING_SUB_ELIGIBILITY,'$999,999,999.00') AS REMAINING_SUB_ELIGIBILITY,
        TO_CHAR(REMAINING_UNSUB_ELIGIBILITY,'$999,999,999.00') AS REMAINING_UNSUB_ELIGIBILITY,
        TO_CHAR(REMAINING_TOTAL_ELIGIBILITY,'$999,999,999.00') AS REMAINING_TOTAL_ELIGIBILITY,
        
        TO_CHAR(ALL_OTHER_TERM_AID, '$999,999,999.00') AS ALL_OTHER_TERM_AID,
        TO_CHAR(TERM_PLUS_OFFERED, '$999,999,999.00') AS TERM_PLUS_OFFERED,
        
        CASE
            WHEN LEGACY_PROGRAM_1 IS NOT NULL
              OR LEGACY_PROGRAM_2 IS NOT NULL
              OR LEGACY_PROGRAM_3 IS NOT NULL
              OR LEGACY_PROGRAM_4 IS NOT NULL
            THEN 'Y'
            ELSE 'N'
        END AS KSU_LEGACY_PROGRAM_ON_FILE,
        
        LEGACY_PROGRAM_1,
        LEGACY_PROGRAM_1_ETTC_TERMS,
        LEGACY_PROGRAM_1_ETTC_YEARS,
        LEGACY_PROGRAM_1_ENDED,

        LEGACY_PROGRAM_2,
        LEGACY_PROGRAM_2_ETTC_TERMS,
        LEGACY_PROGRAM_2_ETTC_YEARS,
        LEGACY_PROGRAM_2_ENDED,

        LEGACY_PROGRAM_3,
        LEGACY_PROGRAM_3_ETTC_TERMS,
        LEGACY_PROGRAM_3_ETTC_YEARS,
        LEGACY_PROGRAM_3_ENDED,

        LEGACY_PROGRAM_4,
        LEGACY_PROGRAM_4_ETTC_TERMS,
        LEGACY_PROGRAM_4_ETTC_YEARS,
        LEGACY_PROGRAM_4_ENDED,

        NSLDS_TREQ,
        NSLDS_STATUS,
        NSLDS_DATE,

        ROBUSDF_VALUE_110,
        ROBUSDF_VALUE_118,
        ROBUSDF_VALUE_119,
        ROBUSDF_VALUE_120,
        HAS_CONSORTIUM_IND_Y,
                
        TERM_TOTAL_FINAID_BILL_HR_FEDAID,
        TERM_TOTAL_FINAID_ADJ_HR_FEDAID,
        TERM_TOTAL_FINAID_BILL_HR_STANDARD,
        TERM_TOTAL_FINAID_ADJ_HR_STANDARD,

        SR_HOLD,
        SR_HOLD_FROM,
        SR_HOLD_TO,
        SR_HOLD_TERM,
        TO_CHAR(TERM_PELL_OFFER,'$999,999,999.00') AS TERM_PELL_OFFER,
        TO_CHAR(TERM_PELL_PAID,'$999,999,999.00') AS TERM_PELL_PAID

    FROM RECONCILED
    WHERE
        CASE
            WHEN NVL(:ACTION_FILTER, 'ALL') = 'ALL' THEN 1
            WHEN :ACTION_FILTER = 'INCREASE' AND COUNSELOR_ACTION = 'INCREASE' THEN 1
            WHEN :ACTION_FILTER = 'DECREASE' AND COUNSELOR_ACTION = 'DECREASE' THEN 1
            WHEN :ACTION_FILTER = 'ADJUST_SUB_UNSUB' AND COUNSELOR_ACTION = 'ADJUST_SUB_UNSUB' THEN 1
            WHEN :ACTION_FILTER = 'OFFER_NEW' AND COUNSELOR_ACTION = 'OFFER_NEW' THEN 1
            WHEN :ACTION_FILTER = 'ANY_CHANGE' AND COUNSELOR_ACTION IN ('INCREASE','DECREASE','ADJUST_SUB_UNSUB','OFFER_NEW') THEN 1
            WHEN :ACTION_FILTER = 'NO_CHANGE' AND COUNSELOR_ACTION = 'NO_CHANGE' THEN 1
            WHEN :ACTION_FILTER = 'REVIEW' AND COUNSELOR_ACTION = 'REVIEW' THEN 1
            ELSE 0
        END = 1
    ORDER BY
        COUNSELOR_ACTION,
        SPRIDEN_LAST_NAME,
        SPRIDEN_FIRST_NAME;

        
