-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Schema fields used internally for joins/comparisons are retained where required by the query logic.
-- Do not commit query results or exports containing student records.

-----***will need to add future aid years to below****--------
select count(distinct(spriden_id)), rprawrd_aidy_code
from spriden
left join rprawrd on rprawrd_pidm = spriden_pidm and rprawrd_aidy_code in ('2021','2122','2223')
left join rorstat on rorstat_pidm = spriden_pidm and rorstat_aidy_code in ('2021','2122','2223')
where spriden_change_ind is null
and rprawrd_orig_offer_date is not null
group by rprawrd_aidy_code