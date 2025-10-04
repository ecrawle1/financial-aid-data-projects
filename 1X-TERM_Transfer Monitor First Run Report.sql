Select * from (

SELECT SPRIDEN_ID, SPRIDEN_LAST_NAME LNAME, SPRIDEN_FIRST_NAME FNAME,

(Select SGBSTDN_STYP_CODE
from SGBSTDN
where  GLBEXTR_KEY = SGBSTDN_PIDM
and SGBSTDN_TERM_CODE_EFF =
                (Select MAX(A.SGBSTDN_TERM_CODE_EFF)
                from SGBSTDN A
                where A.SGBSTDN_PIDM =  GLBEXTR_KEY
                and A.SGBSTDN_TERM_CODE_EFF <='202110')) STU_TYPE,
                
                
  (SELECT SUM(SFRSTCR_CREDIT_HR)
        FROM SFRSTCR A
        WHERE A.SFRSTCR_PIDM =  GLBEXTR_KEY
        and     a.sfrstcr_term_code = '202060'
        AND    A.SFRSTCR_RSTS_CODE IN ('RR','RE','RW','R2')) SUM_HRS,
                
 (SELECT SUM(SFRSTCR_CREDIT_HR)
        FROM SFRSTCR A
        WHERE A.SFRSTCR_PIDM =  GLBEXTR_KEY
        and     a.sfrstcr_term_code = '202080'
        AND    A.SFRSTCR_RSTS_CODE IN ('RR','RE','RW','R2')) FALL_HRS
        

FROM GLBEXTR

LEFT JOIN SPRIDEN
ON          GLBEXTR_KEY = SPRIDEN_PIDM
AND         SPRIDEN_CHANGE_IND IS NULL

LEFT JOIN RPRATRM
ON          GLBEXTR_KEY = RPRATRM_PIDM
AND         RPRATRM_AIDY_CODE = '2021'
AND         RPRATRM_PERIOD = '202110'
AND         RPRATRM_FUND_CODE = 'GFNPEL'


WHERE glbextr_application = 'FINAID'
AND     GLBEXTR_SELECTION = 'FA_TRANSFER_MONITOR_FIRST_SPR3'
AND     GLBEXTR_USER_ID = 'JLRASTET'
AND     GLBEXTR_CREATOR_ID = 'JLRASTET'
--and     RPRATRM_ACCEPT_AMT > 0
)

where FALL_HRS > 0
or SUM_HRS > 0