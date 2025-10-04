SELECT * 
FROM
      (SELECT 
              SPRIDEN_ID                    BNRID,
              SPRIDEN_LAST_NAME             LNAME,
              SPRIDEN_FIRST_NAME            FNAME,
              RORSTAT_APRD_CODE             AID_PERIOD,
              RORSTAT_PCKG_COMP_DATE        PCKG_COMP_DATE,
              RORSTAT_PCKG_REQ_COMP_DATE    PCKG_REQ_COMP_DATE,
              SGBSTDN_STYP_CODE             STUDENT_TYPE,
              SGBSTDN_LEVL_CODE             CLASS_STANDING,
              SGBSTDN_PROGRAM_1             PROGRAM_1,
              (SELECT SUM(SFRSTCR_BILL_HR)
               FROM SFRSTCR
               WHERE RORSTAT_PIDM = SFRSTCR_PIDM 
               AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')
               AND SFRSTCR_TERM_CODE = :SMR_TERM) SMR_BILLED_HRS,
              (SELECT SUM(SFRSTCR_BILL_HR)
               FROM SFRSTCR
               WHERE RORSTAT_PIDM = SFRSTCR_PIDM 
               AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')
               AND SFRSTCR_TERM_CODE = :FAL_TERM) FAL_BILLED_HRS,
              (SELECT SUM(SFRSTCR_BILL_HR)
               FROM SFRSTCR
               WHERE RORSTAT_PIDM = SFRSTCR_PIDM 
               AND SFRSTCR_RSTS_CODE IN ('RE','RR','RW','R2')
               AND SFRSTCR_TERM_CODE = :SPR_TERM) SPR_BILLED_HRS,
              (SELECT SFRTHST_TMST_CODE     
                 FROM 
                 (SELECT SFRTHST_TMST_CODE
                 FROM SFRTHST
                 WHERE RORSTAT_PIDM = SFRTHST_PIDM 
                 AND SFRTHST_TERM_CODE = :SMR_TERM
                 ORDER BY SFRTHST_ACTIVITY_DATE DESC )
                 WHERE ROWNUM = 1) SMR_TMST,
              (SELECT SFRTHST_TMST_CODE     
                 FROM 
                 (SELECT SFRTHST_TMST_CODE
                 FROM SFRTHST
                 WHERE RORSTAT_PIDM = SFRTHST_PIDM 
                 AND SFRTHST_TERM_CODE = :FAL_TERM
                 ORDER BY SFRTHST_ACTIVITY_DATE DESC )
                 WHERE ROWNUM = 1) FAL_TMST,
              (SELECT SFRTHST_TMST_CODE     
                 FROM 
                 (SELECT SFRTHST_TMST_CODE
                 FROM SFRTHST
                 WHERE RORSTAT_PIDM = SFRTHST_PIDM 
                 AND SFRTHST_TERM_CODE = :SPR_TERM
                 ORDER BY SFRTHST_ACTIVITY_DATE DESC )
                 WHERE ROWNUM = 1) SPR_TMST,
              ROBUSDF_VALUE_229             UDF_229,
              ROBUSDF_VALUE_230             UDF_230,
              ROBUSDF_VALUE_231             UDF_231,
              ROBUSDF_VALUE_236             UDF_236,
              ROBUSDF_VALUE_237             UDF_237,
              ROBUSDF_VALUE_238             UDF_238,
              (SELECT MAX(RORSAPR_SAPR_CODE)
                FROM RORSAPR
                WHERE RORSTAT_PIDM = RORSAPR_PIDM 
                AND RORSAPR_TERM_CODE = :SMR_TERM) SMR_SAP,
              (SELECT MAX(RORSAPR_SAPR_CODE)
                FROM RORSAPR
                WHERE RORSTAT_PIDM = RORSAPR_PIDM 
                AND RORSAPR_TERM_CODE = :FAL_TERM)FAL_SAP,
              (SELECT MAX(RORSAPR_SAPR_CODE)
                FROM RORSAPR
                WHERE RORSTAT_PIDM = RORSAPR_PIDM 
                AND RORSAPR_TERM_CODE = :SPR_TERM)SPR_SAP
              
        FROM RORSTAT
        
        LEFT JOIN SPRIDEN
             ON SPRIDEN_PIDM = RORSTAT_PIDM
             AND SPRIDEN_CHANGE_IND IS NULL
        
        LEFT JOIN SGBSTDN
             ON SGBSTDN_PIDM = RORSTAT_PIDM
        
        LEFT JOIN ROBUSDF
             ON ROBUSDF_PIDM = RORSTAT_PIDM
             AND ROBUSDF_AIDY_CODE = RORSTAT_AIDY_CODE
             
        WHERE RORSTAT_AIDY_CODE = :AIDY
        AND SGBSTDN_TERM_CODE_EFF =
    (SELECT MAX(Z.SGBSTDN_TERM_CODE_EFF)
    FROM SGBSTDN Z
    WHERE Z.SGBSTDN_PIDM = RORSTAT_PIDM
    AND Z.SGBSTDN_TERM_CODE_EFF <= :SPR_TERM)
    ORDER BY SPRIDEN_LAST_NAME)
    
    WHERE (SMR_BILLED_HRS IS NOT NULL
       OR FAL_BILLED_HRS IS NOT NULL
       OR SPR_BILLED_HRS IS NOT NULL)
       OR 
       (SMR_TMST IS NOT NULL
       OR FAL_TMST IS NOT NULL
       OR SPR_TMST IS NOT NULL)