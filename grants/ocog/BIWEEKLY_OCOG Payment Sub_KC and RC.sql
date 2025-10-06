    WITH enr AS (
        --Selects billed hours for KC and non-KC
        SELECT
            s.SFRSTCR_PIDM                                   AS PIDM,
            SUM(CASE WHEN s.SFRSTCR_CAMP_CODE = 'KC'
                     THEN s.SFRSTCR_BILL_HR ELSE 0 END)      AS KC_BILLED,
            SUM(CASE WHEN s.SFRSTCR_CAMP_CODE <> 'KC'
                     THEN s.SFRSTCR_BILL_HR ELSE 0 END)      AS RC_BILLED,
            SUM(s.SFRSTCR_BILL_HR)                           AS TOT_BILLED
        FROM SFRSTCR s
        WHERE s.SFRSTCR_TERM_CODE = :TERM
          AND s.SFRSTCR_LEVL_CODE = 'UG'
        GROUP BY s.SFRSTCR_PIDM
    ),

    enr_pct AS (
        --Aggregated selection to determine percentage of hours KC and non-KC
        SELECT
            e.PIDM,
            e.KC_BILLED,
            e.RC_BILLED,
            e.TOT_BILLED,
            ROUND(
            CASE
                WHEN NVL(e.TOT_BILLED,0) = 0 THEN 0
                ELSE e.RC_BILLED / e.TOT_BILLED
            END, 2) AS PERCENT_REGIONAL
        FROM enr e
    ),

    prev_ocog AS (
        --Used to alternate the 100% regional OCOG amounts so that the cents will be correct
        SELECT
            r.RPRATRM_PIDM                                    AS PIDM,
            MAX(r.RPRATRM_PAID_AMT) KEEP (DENSE_RANK LAST ORDER BY r.RPRATRM_PERIOD) AS OCOG_AMT_PREV
        FROM RPRATRM r
        WHERE r.RPRATRM_AIDY_CODE = :AIDY
          AND r.RPRATRM_PERIOD    < :TERM               -- prior terms only
          AND r.RPRATRM_FUND_CODE IN ('GSNOCR','GSNOCG')
          AND r.RPRATRM_PAID_AMT IN (99.37, 99.38, 33.12, 33.13)
        GROUP BY r.RPRATRM_PIDM
    ),
    
    base AS (
        -- This CTE is creating all of the columns to be included in the report, including some that are calculated from the other CTE's above (example ep. table)
        SELECT
            DISTINCT p.SPRIDEN_ID                     AS ID,
            p.SPRIDEN_LAST_NAME                       AS LNAME,
            p.SPRIDEN_FIRST_NAME                      AS FNAME,
            b.SPBPERS_SSN                             AS SSN,
            u.ROBUSDF_VALUE_141                       AS DISBURSED_AMT,  --- update the ROBUSDF VALUE FOR EACH TERM
            u.ROBUSDF_VALUE_142                       AS BATCH_ID,       --- update the ROBUSDF VALUE FOR EACH TERM
            u.ROBUSDF_VALUE_143                       AS ADJUSTED_AMT,   --- update the ROBUSDF VALUE FOR EACH TERM
            u.ROBUSDF_VALUE_157                       AS OBR_UNITS,
            u.ROBUSDF_VALUE_158                       AS OBR_EXHAUSTED,
            u.ROBUSDF_VALUE_152                       AS SKIP_CODE,      --- update the ROBUSDF VALUE FOR EACH TERM
            ts.RPRATRM_FUND_CODE                      AS TS_FUND,
            ts.RPRATRM_OFFER_AMT                      AS TS_FUND_OFFER_AMT,
            ts.RPRATRM_AWST_CODE                      AS TS_FUND_STATUS,
            cs.RORENRL_CONSORTIUM_IND                 AS CONSORTIUM_IND,

            ep.KC_BILLED,
            ep.RC_BILLED,
            ep.TOT_BILLED,
            ep.PERCENT_REGIONAL,
            (SELECT SUM(TBRACCD_AMOUNT)
             FROM TBRACCD
             WHERE TBRACCD_PIDM = SPRIDEN_PIDM
             AND TBRACCD_TERM_CODE = :TERM        
             AND TBRACCD_DETAIL_CODE IN ('JIEG','TKGT','TKGU','TKUT', 'TKUU', 'TRUT', 'TRUU', 'FKCS', 'FRCS','TSNT','TSNU','TCPG','TCPI','FACS')
             ) BILLABLE_CHRGES,

            -- Use completed credit hours to determine student_level
            CASE
                WHEN g.SHRLGPA_HOURS_EARNED > '90' THEN 'SR'
                WHEN g.SHRLGPA_HOURS_EARNED > '60' THEN 'JR'
                WHEN g.SHRLGPA_HOURS_EARNED > '30' THEN 'SO'
                ELSE 'FR'
            END AS CLASS_STAND,

            -- This is the pacaking load from RPAATRM
            CASE r.RPRATRM_PCKG_LOAD_IND
                WHEN '1' THEN 'FT'
                WHEN '2' THEN 'TT'
                WHEN '3' THEN 'HT'
                WHEN '4' THEN 'QT'
                ELSE '00'
            END AS RPAAWRD_TM,

            -- This will be their actual time status based on registered hours- used to update the packaging load by Grants team
            CASE
                WHEN NVL(ep.TOT_BILLED,0) >= '12' THEN 'FT'
                WHEN NVL(ep.TOT_BILLED,0) >   '8' THEN 'TT'
                WHEN NVL(ep.TOT_BILLED,0) >   '5' THEN 'HT'
                ELSE 'QT'
            END AS SFAREGS_TM,

            r.RPRATRM_PAID_AMT                         AS PAID_AMT,
            r.RPRATRM_PCKG_LOAD_IND                    AS LOAD_IND_NUM,
            r.RPRATRM_LOCK_IND                         AS LOCK_IND,
            r.RPRATRM_OVERRIDE_DISB_RULE               AS OVERRIDE_IND,
            po.OCOG_AMT_PREV
            
        FROM SPRIDEN p
        
        LEFT JOIN SPBPERS b
               ON b.SPBPERS_PIDM = p.SPRIDEN_PIDM
               
        LEFT JOIN SHRLGPA g
               ON g.SHRLGPA_PIDM = p.SPRIDEN_PIDM
              AND g.SHRLGPA_GPA_TYPE_IND = 'O'
              AND g.SHRLGPA_LEVL_CODE    = 'UG'
              
        LEFT JOIN RPRATRM r
               ON r.RPRATRM_PIDM   = p.SPRIDEN_PIDM
              AND r.RPRATRM_PERIOD = :TERM
              AND r.RPRATRM_FUND_CODE IN ('GSNOCG', 'GSNOCR', 'GSNOCX', 'GSNO2E')
              
        LEFT JOIN ROBUSDF u
               ON u.ROBUSDF_PIDM = p.SPRIDEN_PIDM
              AND u.ROBUSDF_AIDY_CODE = :AIDY
              
        LEFT JOIN RORENRL cs
               ON p.SPRIDEN_PIDM = cs.RORENRL_PIDM
              AND cs.RORENRL_TERM_CODE = :TERM
               
        LEFT JOIN enr_pct ep
               ON ep.PIDM = p.SPRIDEN_PIDM
               
        LEFT JOIN prev_ocog po
               ON po.PIDM = p.SPRIDEN_PIDM
        
        LEFT JOIN RPRATRM ts
               ON ts.RPRATRM_PIDM = SPRIDEN_PIDM
               AND ts.RPRATRM_PERIOD = :TERM
               AND ts.RPRATRM_FUND_CODE IN ('SSOWOS','SSOGSA','WIWFWE','WIWFWO')
               AND NVL(ts.RPRATRM_OFFER_AMT, 0) > 0
               
        WHERE p.SPRIDEN_CHANGE_IND IS NULL
          AND r.RPRATRM_PAID_AMT > 0
          AND (u.ROBUSDF_VALUE_143 IS NULL OR u.ROBUSDF_VALUE_141 <> r.RPRATRM_PAID_AMT)  --- update the ROBUSDF VALUE FOR EACH TERM
    ),
    
    ocog_calc AS (
        -- Additional CTE for calculating the amount of OCOG that should be paid to the student, instead of just what is reported on RPAATRM which could be wrong - this finds paid amount errors
        SELECT
            b.*,
            CASE
                WHEN NVL(b.PERCENT_REGIONAL,0) = 0 THEN
                    /* 100% Kent Campus flat awards by load */
                    CASE b.LOAD_IND_NUM
                        WHEN '1' THEN '2000'
                        WHEN '2' THEN '1500'
                        WHEN '3' THEN '1000'
                        WHEN '4' THEN '500'
                    END
                WHEN b.PERCENT_REGIONAL = 1 THEN
                    /* 100% Regional with alternate rounding based on prior-term paid */
                    CASE b.LOAD_IND_NUM
                        WHEN '1' THEN '132.50'
                        WHEN '2' THEN CASE WHEN b.OCOG_AMT_PREV = '99.38' THEN '99.37' ELSE '99.38' END
                        WHEN '3' THEN '66.25'
                        WHEN '4' THEN CASE WHEN b.OCOG_AMT_PREV = '33.13' THEN '33.12' ELSE '33.13' END
                    END
                ELSE
                    /* IF we get any confirmation of a DUAL OCOG formula to be used for students 51-99% regional, that formual would go here */
                    NULL
            END AS OCOG_CALC
        FROM base b
    )
    SELECT
        ID,
        LNAME,
        FNAME,
        SSN,
        DISBURSED_AMT,  --- update the ROBUSDF VALUE FOR EACH TERM
        BATCH_ID,       --- update the ROBUSDF VALUE FOR EACH TERM
        ADJUSTED_AMT,   --- update the ROBUSDF VALUE FOR EACH TERM
        CLASS_STAND,
        SFAREGS_TM,
        RPAAWRD_TM,
        PAID_AMT,
        /* Adjustment flags */
        CASE
            WHEN DISBURSED_AMT IS NULL THEN 'F'      --- update the ROBUSDF VALUE FOR EACH TERM
            WHEN PAID_AMT > DISBURSED_AMT THEN 'I'   --- update the ROBUSDF VALUE FOR EACH TERM
            WHEN PAID_AMT < DISBURSED_AMT THEN 'R'   --- update the ROBUSDF VALUE FOR EACH TERM
        END AS ADJUSTMENT,
                
        /* This determines the amount that should be submitted to HEI when an adjustment (R -reduction or I - increase) is needed for the submission file */
        CASE
            WHEN (CASE
                    WHEN DISBURSED_AMT IS NULL THEN 'F'
                    WHEN PAID_AMT > DISBURSED_AMT THEN 'I'
                    WHEN PAID_AMT < DISBURSED_AMT THEN 'R'
                  END) = 'R'
                THEN PAID_AMT - DISBURSED_AMT
            WHEN (CASE
                    WHEN DISBURSED_AMT IS NULL THEN 'F'
                    WHEN PAID_AMT > DISBURSED_AMT THEN 'I'
                    WHEN PAID_AMT < DISBURSED_AMT THEN 'R'
                  END) = 'I'
                THEN DISBURSED_AMT - PAID_AMT
            ELSE PAID_AMT
        END AS PAYMENT_SUB,

        /* Additional columns to help Grants Team correct students with either hours, paid amount, or units errors */
        BILLABLE_CHRGES,
        LEAST(ROUND((TOT_BILLED / 12) * 100, 2), 100) AS ENROLLMENT_INTENSITY_PCT,
        ROUND((7395 * ROUND(TOT_BILLED / 12, 2)) / 2, 0) AS MAX_PELL_ELIG,
        BILLABLE_CHRGES - ROUND((7395 * ROUND(TOT_BILLED / 12, 2)) / 2, 0) AS OCOG_ELIGIBILITY,
        TS_FUND_OFFER_AMT,
        KC_BILLED,
        RC_BILLED,
        TOT_BILLED,
        PERCENT_REGIONAL,
        OCOG_CALC, 
        OBR_UNITS,
        OBR_EXHAUSTED,
        CASE WHEN SKIP_CODE IS NOT NULL THEN 'Y'
        ELSE NULL
        END AS SKIPPED_IND,
        CASE WHEN LOCK_IND IS NOT NULL THEN 'Y'
        ELSE NULL
        END AS LOCKED_IND,
        CASE WHEN OVERRIDE_IND IS NOT NULL THEN 'Y'
        ELSE NULL
        END AS OVERRIDE_ISSUED,
        CONSORTIUM_IND

    FROM ocog_calc
    WHERE (DISBURSED_AMT IS NULL 
           OR (DISBURSED_AMT IS NOT NULL
            AND (PAID_AMT > DISBURSED_AMT
            OR PAID_AMT < DISBURSED_AMT)) )
    ORDER BY LNAME, FNAME;
