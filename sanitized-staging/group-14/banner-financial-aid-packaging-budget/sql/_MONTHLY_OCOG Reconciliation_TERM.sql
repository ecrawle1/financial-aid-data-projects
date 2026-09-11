/*
FERPA-SAFE PUBLIC VERSION
Direct student/borrower identifiers have been removed or masked from the final result set where practical.
Hard-coded student IDs, SSNs, personal email values, individualized free-text output, and staff user identifiers were removed or parameterized where applicable.
Schema fields may remain internally where required for joins, filtering, calculation, or comparison logic.
This repository contains SQL code only. Do not commit query output or student-level data.
*/

WITH award_base AS (
    SELECT
        rt.rpratrm_pidm                        AS pidm,
        rw.rprawrd_aidy_code                   AS aidy_code,
        rt.rpratrm_period                      AS term_code,
        rt.rpratrm_fund_code                   AS fund_code,

        SUM(NVL(rt.rpratrm_offer_amt, 0))      AS award_offer_amount,
        SUM(NVL(rt.rpratrm_accept_amt, 0))     AS award_accept_amount,
        SUM(NVL(rt.rpratrm_paid_amt, 0))       AS award_paid_amount,

        MAX(rt.rpratrm_paid_date)              AS award_paid_date,
        rt.rpratrm_pckg_load_ind               AS time_status,
              
        CASE WHEN rt.rpratrm_pckg_load_ind ='1' THEN 'FT'
        WHEN rt.rpratrm_pckg_load_ind ='2'  THEN 'TT'
        WHEN rt.rpratrm_pckg_load_ind ='3' THEN 'HT'
        WHEN rt.rpratrm_pckg_load_ind ='4' THEN 'QT'
        WHEN rt.rpratrm_pckg_load_ind ='5' THEN 'NE'
        ELSE NULL END                           AS time_status_desc
                
    FROM rprawrd rw
    JOIN rpratrm rt
      ON rt.rpratrm_pidm      = rw.rprawrd_pidm
     AND rt.rpratrm_aidy_code = rw.rprawrd_aidy_code
     AND rt.rpratrm_fund_code = rw.rprawrd_fund_code
    WHERE rw.rprawrd_aidy_code = :AIDY
      AND rt.rpratrm_period    = :TERM
      AND rt.rpratrm_fund_code IN ('GSNOCG','GSNOCR','GSNOCX','GSNOCE', 'GSNOC2E')
      AND NVL(rt.rpratrm_paid_amt, 0) > 0
    GROUP BY
        rt.rpratrm_pidm,
        rw.rprawrd_aidy_code,
        rt.rpratrm_period,
        rt.rpratrm_fund_code,
        rt.rpratrm_pckg_load_ind
),

person_data AS (
    SELECT
        s.spriden_pidm                         AS pidm,
        s.spriden_id                           AS id,
        s.spriden_last_name
            || ', ' ||
        s.spriden_first_name
            || NVL2(s.spriden_mi, ' ' || s.spriden_mi, '') AS name,
        p.spbpers_ssn                          AS tax_id
    FROM spriden s
    LEFT JOIN spbpers p
      ON p.spbpers_pidm = s.spriden_pidm
    WHERE s.spriden_change_ind IS NULL
),

billed_hours AS (
    SELECT
        r.sfrstcr_pidm                         AS pidm,
        SUM(NVL(r.sfrstcr_bill_hr, 0))         AS total_billing,
        CASE
          WHEN SUM(NVL(r.sfrstcr_bill_hr, 0)) >= 12 THEN 'FT'
          WHEN SUM(NVL(r.sfrstcr_bill_hr, 0)) >= 9  THEN 'TT'
          WHEN SUM(NVL(r.sfrstcr_bill_hr, 0)) >= 6  THEN 'HT'
          WHEN SUM(NVL(r.sfrstcr_bill_hr, 0)) >= 1  THEN 'QT'
          ELSE NULL
        END                                     AS time_status_load
    FROM sfrstcr r
    WHERE r.sfrstcr_term_code = :TERM
    GROUP BY r.sfrstcr_pidm
),

classification AS (
    SELECT
        s.sgbstdn_pidm                         AS pidm,
        s.sgbstdn_styp_code                    AS student_classification_boap
    FROM sgbstdn s
    WHERE s.sgbstdn_term_code_eff =
        (SELECT MAX(s2.sgbstdn_term_code_eff)
         FROM sgbstdn s2
         WHERE s2.sgbstdn_pidm = s.sgbstdn_pidm
           AND s2.sgbstdn_term_code_eff <= :TERM)
),

udf_billing AS (
    SELECT
        ROBUSDF_PIDM                            AS id,
        ROBUSDF_VALUE_138                       AS user_field_138,
        ROBUSDF_VALUE_139                       AS user_field_139,
        ROBUSDF_VALUE_140                       AS user_field_140,
        ROBUSDF_VALUE_141                       AS user_field_141,
        ROBUSDF_VALUE_142                       AS user_field_142,
        ROBUSDF_VALUE_143                       AS user_field_143,
        ROBUSDF_VALUE_144                       AS user_field_144,
        ROBUSDF_VALUE_145                       AS user_field_145,
        ROBUSDF_VALUE_146                       AS user_field_146
    FROM ROBUSDF
    WHERE ROBUSDF_AIDY_CODE = :AIDY
)

SELECT
    NULL AS tax_id,
    c.student_classification_boap,
    bh.time_status_load,
    LPAD(TO_CHAR(ROUND(ab.award_paid_amount * 100, 0)), 6, '0') AS paid_amount_formatted_part_2,
    ab.award_paid_amount,
    ab.award_paid_date,
    ROUND(ab.award_paid_amount * 100, 0)         AS paid_amount_formatted_part_1,
    NULL AS id,
    NULL AS name,
    ab.term_code                                AS aid_enrollment_period,
    ab.fund_code                                AS fund,
    ab.award_offer_amount,
    ab.award_accept_amount,
    bh.total_billing,
    CASE
        WHEN NVL(bh.total_billing, 0) >= 12 THEN 'FT'
        WHEN NVL(bh.total_billing, 0) >= 9  THEN 'TT'
        WHEN NVL(bh.total_billing, 0) >= 6  THEN 'HT'
        WHEN NVL(bh.total_billing, 0) >= 1  THEN 'QT'
        ELSE NULL
    END                                          AS time_status_billed_hours,
    CASE
        WHEN bh.time_status_load IS NULL
          OR ab.time_status_desc IS NULL
        THEN 'N'
        WHEN bh.time_status_load = ab.time_status_desc
        THEN 'Y'
        ELSE 'N'
    END                                          AS hours_match,
    ab.time_status, 
    ab.time_status_desc,
    u.user_field_138,
    u.user_field_139,
    u.user_field_140,
    u.user_field_141,
    u.user_field_142,
    u.user_field_143,
    u.user_field_144,
    u.user_field_145,
    u.user_field_146

FROM award_base ab
JOIN person_data pd
  ON pd.pidm = ab.pidm
LEFT JOIN billed_hours bh
  ON bh.pidm = ab.pidm
LEFT JOIN classification c
  ON c.pidm = ab.pidm
LEFT JOIN udf_billing u
  ON u.id = pd.pidm

ORDER BY
    pd.name,
    pd.id,
    ab.fund_code;