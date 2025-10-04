select distinct spriden_id, spriden_last_name, spriden_first_name, A.RRRAREQ_PERIOD AHCAG_Period, A.RRRAREQ_TREQ_CODE AHCAG_TRAQ, B.RRRAREQ_PERIOD AHCAR_Period, B.RRRAREQ_TREQ_CODE AHCAR_TRAQ, B.RRRAREQ_TRST_CODE AHCAR_STATUS, SHRTGPA_TERM_CODE, SHRTGPA_GPA_TYPE_IND, SHRTGPA_HOURS_ATTEMPTED, SHRTGPA_HOURS_EARNED

from rrrareq A

left join spriden
on A.rrrareq_pidm = spriden_pidm 
and spriden_change_ind is null 

left join shrtgpa
on A.rrrareq_pidm=shrtgpa_pidm
and SHRTGPA_GPA_TYPE_IND = 'T'
and SHRTGPA_TERM_CODE in (:SUM_TRM, :FAL_TRM, :SPR_TERM)

left join RRRAREQ B
on A.rrrareq_pidm = b.rrrareq_pidm
and A.RRRAREQ_PERIOD = B.RRRAREQ_PERIOD
and B.RRRAREQ_TREQ_CODE ='AHCAR'


where A.RRRAREQ_AIDY_CODE =:Aid_Year 
and A.RRRAREQ_TREQ_CODE ='AHCAG'
and A.RRRAREQ_TRST_CODE ='A'
