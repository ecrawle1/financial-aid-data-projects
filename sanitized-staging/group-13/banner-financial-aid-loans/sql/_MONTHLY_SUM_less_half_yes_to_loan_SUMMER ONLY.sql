-- SANITIZED PUBLIC VERSION
-- Direct student/borrower identifiers and hard-coded student data have been removed from public output.
-- Literal student ID/SSN lists have been replaced with bind parameters where applicable.
-- Schema fields may remain internally where required for joins, filtering, or comparison logic.
-- Do not commit query results or exports containing student records.

select NULL AS STUDENT_ID, NULL AS STUDENT_LAST_NAME, NULL AS STUDENT_FIRST_NAME, 
        ROBUSDF_VALUE_201 SMR_LOAN, 
        
        CASE WHEN RORSTAT_XES = '4'
        THEN '4 = Less Than 1/2 Time'
        END AS Expected_Enrollment_Status,
        
        
        (SELECT SUM(SFRSTCR_CREDIT_HR)
        FROM SFRSTCR
        WHERE SFRSTCR_PIDM = RORSTAT_PIDM
        AND     SFRSTCR_TERM_CODE = :TERM
        AND     SFRSTCR_LEVL_CODE = 'UG'
        AND     SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) TERM_UG_ENRL,  
        
        (SELECT SUM(SFRSTCR_CREDIT_HR)
        FROM SFRSTCR
        WHERE SFRSTCR_PIDM = RORSTAT_PIDM
        AND     SFRSTCR_TERM_CODE = :TERM
        AND     SFRSTCR_LEVL_CODE IN ('GR','PR')
        AND     SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')) TERM_GR_PR_ENRL
        
FROM RORSTAT

LEFT JOIN SPRIDEN
ON          RORSTAT_PIDM = SPRIDEN_PIDM
AND         SPRIDEN_CHANGE_IND IS NULL

LEFT JOIN ROBUSDF
ON          RORSTAT_PIDM = ROBUSDF_PIDM
AND         RORSTAT_AIDY_CODE = ROBUSDF_AIDY_CODE

WHERE RORSTAT_AIDY_CODE = :AIDY
AND     RORSTAT_XES = '4' 
AND     ROBUSDF_VALUE_201 LIKE 'Y%'
