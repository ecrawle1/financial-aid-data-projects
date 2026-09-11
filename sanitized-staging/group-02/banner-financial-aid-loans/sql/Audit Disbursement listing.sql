-- SANITIZED PUBLIC VERSION
-- Direct student identifiers and hard-coded student data have been removed from report output.
-- Schema fields used internally for joins/comparisons are retained where required by the query logic.
-- Do not commit query results or exports containing student records.

-- Direct Loan detail for day to break batch out from staff disb if not run early in day
select tbraccd_detail_code, tbraccd_desc, sum(tbraccd_amount), tbraccd_term_code, (tbraccd_entry_date), TBRACCD_AIDY_CODE, TBRACCD_FEED_DOC_CODE
from spriden, tbraccd
where spriden_pidm = tbraccd_pidm
and spriden_change_ind is null
and tbraccd_detail_code IN ('LFG1','LFG2','LFGA','LFGB','LFGC','LFGD','LFGE','LFGF','LFGG','LFGH','LFGO','LFS1','LFS2','LFS3','LFSA','LFSB','LFSC','LFSD','LFSE','LFSF','LFSG','LFSH','LFU1','LFU2','LFU3','LFUA','LFUB','LFUC','LFUD','LFUE','LFUF','LFUO','LFUP','LFUQ','LFP1','LFP2','LFPA','LFPB','LFPC','LFPD','LFPE','LFPF','LFPG')
-- Additional Pell/SEOG/TEACH filters retained from original query as written.
and trunc(tbraccd_effective_date) >= '15-MAY-2022'
and tbraccd_term_code IN ('202260','202275','202280','202305','202310','202355')
group by tbraccd_detail_code, tbraccd_desc, (tbraccd_entry_date), tbraccd_term_code,TBRACCD_AIDY_CODE, TBRACCD_FEED_DOC_CODE
order by tbraccd_entry_date