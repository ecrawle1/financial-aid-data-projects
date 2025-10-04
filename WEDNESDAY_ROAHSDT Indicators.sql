select spriden_id, spriden_last_name, spriden_first_name,RORHSDT_ADMISSION_TEST_IND

from RORHSDT, spriden
where spriden_pidm = rorhsdt_pidm
and     RORHSDT_ADMISSION_TEST_IND = 'Y'
and     spriden_change_ind is null