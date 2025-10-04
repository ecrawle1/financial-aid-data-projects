select distinct spriden_id BNRID, spriden_last_name LNAME, spriden_first_name FNAME, SGBSTDN_STYP_CODE, SGBSTDN_TERM_CODE_EFF, SGBSTDN_STST_CODE

from SGBSTDN

left join spriden
on SGBSTDN_PIDM = spriden_pidm
and spriden_change_ind is null


where SGBSTDN_STYP_CODE in ('G','W')
and SGBSTDN_STST_CODE = 'AS'
and SGBSTDN_TERM_CODE_EFF = 
(Select MAX(A.SGBSTDN_TERM_CODE_EFF)
from SGBSTDN A
where A.SGBSTDN_PIDM = SGBSTDN_PIDM
and A.SGBSTDN_STST_CODE = 'AS'
and A.SGBSTDN_TERM_CODE_EFF <='202510')