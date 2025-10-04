SELECT ID,
       LNAME,
       FNAME,
       SSN,
       ROBUSDF_VALUE_141,
       ADJUSTED_AMT,
       CLASS_STAND,
       SFAREGS_TM,
       RPAAWRD_TM,
       PAID_AMT,
       ADJUSTMENT,
       CASE
           WHEN ADJUSTMENT = 'R' THEN PAID_AMT - ROBUSDF_VALUE_141
           WHEN ADJUSTMENT = 'I' THEN ROBUSDF_VALUE_141 - PAID_AMT
           ELSE PAID_AMT
       END    AS PAYMENT_SUB
       
  FROM (SELECT ID,
               LNAME,
               FNAME,
               SSN,
               ROBUSDF_VALUE_141,
               ADJUSTED_AMT,
               CLASS_STAND,
               CASE
                   WHEN RPRATRM_PCKG_LOAD_IND = 1 THEN 'FT'
                   WHEN RPRATRM_PCKG_LOAD_IND = 2 THEN 'TT'
                   WHEN RPRATRM_PCKG_LOAD_IND = 3 THEN 'HT'
                   WHEN RPRATRM_PCKG_LOAD_IND = 4 THEN 'QT'
                   ELSE '00'
               END      AS RPAAWRD_TM,
               
               (CASE
                    WHEN BILLED_HRS >= 12 THEN 'FT'
                    WHEN BILLED_HRS > 8 THEN 'TT'
                    WHEN BILLED_HRS > 5 THEN 'HT'
                    ELSE 'QT'
                END)    SFAREGS_TM,
                
               PAID_AMT,
               CASE
                   WHEN ROBUSDF_VALUE_141 IS NULL THEN 'F'
                   WHEN PAID_AMT > ROBUSDF_VALUE_141 THEN 'I'
                   WHEN PAID_AMT < ROBUSDF_VALUE_141 THEN 'R'
               END      AS ADJUSTMENT
               
          FROM (SELECT SPRIDEN_ID             AS ID,
                       SPRIDEN_LAST_NAME      AS LNAME,
                       SPRIDEN_FIRST_NAME     AS FNAME,
                       SPBPERS_SSN            AS SSN,
                       ROBUSDF_VALUE_141,
                       ROBUSDF_VALUE_143      AS ADJUSTED_AMT,
                       
                       (SELECT SUM (SFRSTCR_BILL_HR)
                          FROM SFRSTCR
                         WHERE     SPRIDEN_PIDM = SFRSTCR_PIDM
                               AND SFRSTCR_TERM_CODE = '202480'
                               AND SFRSTCR_RSTS_CODE IN ('RR',
                                                         'RW',
                                                         'R2',
                                                         'RE'))  AS BILLED_HRS,
                       (CASE
                            WHEN SHRLGPA_HOURS_EARNED > 90 THEN 'SR'
                            WHEN SHRLGPA_HOURS_EARNED > 60 THEN 'JR'
                            WHEN SHRLGPA_HOURS_EARNED > 30 THEN 'SO'
                            ELSE 'FR'
                        END)
                           CLASS_STAND,
                           
                       RPRATRM_PCKG_LOAD_IND,
                       --        (CASE
                       --        WHEN RPRATRM_PAID_AMT >= 2000
                       --        THEN 'FT'
                       --        WHEN RPRATRM_PAID_AMT > 1499
                       --        THEN 'TT'
                       --        WHEN RPRATRM_PAID_AMT > 999
                       --        THEN 'HT'
                       --        ELSE 'QT'
                       --        END) TM,

                       RPRATRM_PAID_AMT PAID_AMT   
                                                              --'F'
                  FROM SPRIDEN
                       
                       LEFT JOIN SPBPERS ON SPRIDEN_PIDM = SPBPERS_PIDM
                       
                       LEFT JOIN SHRLGPA
                           ON     SPRIDEN_PIDM = SHRLGPA_PIDM
                              AND SHRLGPA_GPA_TYPE_IND = 'O'
                              AND SHRLGPA_LEVL_CODE = 'UG'
                       
                       LEFT JOIN RPRATRM
                           ON     SPRIDEN_PIDM = RPRATRM_PIDM
                              AND RPRATRM_PERIOD = '202480'
                              AND RPRATRM_FUND_CODE = 'GSNOCG'
                       
                       LEFT JOIN ROBUSDF ON SPRIDEN_PIDM = ROBUSDF_PIDM
                 
                 WHERE     SPRIDEN_CHANGE_IND IS NULL
                       AND ROBUSDF_AIDY_CODE = '2425'
                       AND RPRATRM_PAID_AMT > 0
                       AND (   ROBUSDF_VALUE_142 IS NULL
                            OR ROBUSDF_VALUE_141 <> RPRATRM_PAID_AMT)))