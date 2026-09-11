-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Literal student ID/SSN lists have been replaced with bind parameters where applicable.
-- Schema fields may remain internally where required for joins or comparison logic.
-- Do not commit query results or exports containing student records.

Select ROBUSDF_VALUE_236 FIELD_236, ROBUSDF_VALUE_237 FIELD_237, ROBUSDF_VALUE_238 FIELD_238,
RHRCOMM_CATEGORY_CODE UGGR_Comment

FROM ROBUSDF

LEFT JOIN RHRCOMM
ON RHRCOMM_PIDM = ROBUSDF_PIDM

WHERE 
ROBUSDF_AIDY_CODE = '2425'
and (ROBUSDF_VALUE_236 is not null
or ROBUSDF_VALUE_237 is not null
or ROBUSDF_VALUE_238 is not null)
AND RHRCOMM_CATEGORY_CODE = 'UGGR'
