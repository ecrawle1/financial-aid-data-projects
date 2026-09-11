-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Literal student ID/SSN lists have been replaced with bind parameters where applicable.
-- Schema fields may remain internally where required for joins or comparison logic.
-- Do not commit query results or exports containing student records.

SELECT DISTINCT RORWTXT_AIDY_CODE AIDY, RORWTXT_ACTIVE_IND ACTIVE, RORWTXT_WTXT_CODE CODE, RORWTXT_TAB TAB, RORWTXT_SELECT_VALUE, RORWTXT_HEADING, 
RORWTXT_TEXT

FROM RORWTXT

WHERE RORWTXT_ACTIVE_IND = 'Y'

Order by 1 DESC, 4
