-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Schema fields used internally for joins/comparisons are retained where required by the query logic.
-- Do not commit query results or exports containing student records.

select RLRDLDD_AIDY_CODE, CREATE_DATE, RLRDLDD_FUND_CODE, LOAN_TYPE, RLRDLOR_STATUS, RLRDLOR_YR_IN_COLL, RLRDLDD_PERIOD, DISB_NO, EFFECT_DATE,
CCP_ADM_TERM, F_T_ADM_TERM, STVTERM_START_DATE, SGBSTDN_LEVEL, REG_2627
FROM
(
SELECT RLRDLDD_AIDY_CODE, RLRDLOR_CREATE_DATE CREATE_DATE, RLRDLOR_LOAN_TYPE LOAN_TYPE, RLRDLOR_STATUS, RLRDLOR_YR_IN_COLL,
RLRDLDD_FUND_CODE, A.RLRDLDD_PERIOD RLRDLDD_PERIOD, A.RLRDLDD_DISB_NO DISB_NO, A.RLRDLDD_ENROLLMENT_EFFECT_DATE EFFECT_DATE,
(SELECT MAX(P.SARADAP_TERM_CODE_ENTRY) FROM saradap p, sarappd a, stvapdc WHERE p.saradap_pidm = rprawrd_pidm AND p.saradap_pidm = a.sarappd_pidm AND p.saradap_term_code_entry = a.sarappd_term_code_entry AND p.saradap_appl_no = a.sarappd_appl_no AND A.SARAPPD_APDC_CODE = stvapdc_code AND STVAPDC_STDN_ACC_IND = 'Y' AND stvapdc_inst_acc_ind = 'Y' AND p.saradap_levl_code = 'UG' and p.saradap_styp_code in ('xF','xT','R') AND a.sarappd_seq_no = (SELECT MAX(b.sarappd_seq_no) FROM sarappd b WHERE a.sarappd_pidm = b.sarappd_pidm AND a.sarappd_term_code_entry = b.sarappd_term_code_entry AND a.sarappd_appl_no = b.sarappd_appl_no)) CCP_ADM_TERM,
(SELECT MIN(P.SARADAP_TERM_CODE_ENTRY) FROM saradap p, sarappd a, stvapdc WHERE p.saradap_pidm = rprawrd_pidm AND p.saradap_pidm = a.sarappd_pidm AND p.saradap_term_code_entry = a.sarappd_term_code_entry AND p.saradap_appl_no = a.sarappd_appl_no AND A.SARAPPD_APDC_CODE = stvapdc_code AND STVAPDC_STDN_ACC_IND = 'Y' AND stvapdc_inst_acc_ind = 'Y' AND p.saradap_levl_code = 'UG' and p.saradap_styp_code in ('F','T','xR') AND a.sarappd_seq_no = (SELECT MAX(b.sarappd_seq_no) FROM sarappd b WHERE a.sarappd_pidm = b.sarappd_pidm AND a.sarappd_term_code_entry = b.sarappd_term_code_entry AND a.sarappd_appl_no = b.sarappd_appl_no)) F_T_ADM_TERM,
(SELECT SGBSTDN_LEVL_CODE FROM SGBSTDN WHERE SGBSTDN_PIDM = RPRAWRD_PIDM AND SGBSTDN_TERM_CODE_EFF = (SELECT MAX(SGBSTDN_TERM_CODE_EFF) FROM SGBSTDN Z WHERE Z.SGBSTDN_PIDM = RPRAWRD_PIDM AND Z.SGBSTDN_TERM_CODE_EFF <= '202660')) SGBSTDN_LEVEL,
(SELECT DISTINCT 'Y' FROM SFRSTCR WHERE SFRSTCR_PIDM = RPRAWRD_PIDM AND SFRSTCR_TERM_CODE IN ('202660','202680') AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) REG_2627
FROM RPRAWRD
LEFT JOIN SPRIDEN ON SPRIDEN_PIDM = RPRAWRD_PIDM AND SPRIDEN_CHANGE_IND IS NULL
LEFT JOIN RLRDLOR ON RLRDLOR_PIDM = RPRAWRD_PIDM AND RLRDLOR_AIDY_CODE = RPRAWRD_AIDY_CODE AND RLRDLOR_FUND_CODE = RPRAWRD_FUND_CODE
LEFT JOIN RLRDLDD A ON RPRAWRD_PIDM = A.RLRDLDD_PIDM AND RLRDLOR_LOAN_NO = A.RLRDLDD_LOAN_NO
WHERE RPRAWRD_AIDY_CODE = '2627' AND RPRAWRD_FUND_CODE LIKE 'LF%' AND RPRAWRD_ACCEPT_AMT > 0
)
LEFT JOIN STVTERM ON STVTERM_CODE = F_T_ADM_TERM
WHERE CCP_ADM_TERM IS NOT NULL AND SGBSTDN_LEVEL = 'UG' AND RLRDLOR_STATUS = 'R'
ORDER BY RLRDLDD_PERIOD, EFFECT_DATE;