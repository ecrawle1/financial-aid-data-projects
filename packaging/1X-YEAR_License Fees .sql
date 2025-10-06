
  SELECT *
    FROM (SELECT SPRIDEN_ID                      BID,
                 SPRIDEN_FIRST_NAME              FNAME,
                 SPRIDEN_LAST_NAME               LNAME,
                 SGBSTDN_TERM_CODE_EFF           MAJR_TERM,
                 SGBSTDN_MAJR_CODE_1             MAJR,
                 CASE
                     WHEN RORSTAT_APPL_RCVD_DATE IS NOT NULL THEN 'Y'
                     ELSE 'N'
                 END
                     FAFSA,
                 (SELECT sfrthst_tmst_code
                    FROM sfrthst
                   WHERE     sfrthst_pidm = spriden_pidm
                         AND sfrthst_term_code = :FAL
                         AND sfrthst_activity_date =
                             (SELECT MAX (sfrthst_activity_date)
                                FROM sfrthst x
                               WHERE     x.sfrthst_pidm = spriden_pidm
                                     AND x.sfrthst_term_code = :FAL))
                     FALL_TMST,
                 RORSTAT_PCKG_REQ_COMP_DATE                   PKG_REQ_COMP,
                 TRUNC (RORSTAT_PCKG_COMP_DATE)               PCKG_DATE,
                 SHRLGPA_LEVL_CODE                            LEVL,
                 SHRLGPA_HOURS_EARNED                         EARNED_HRS,
                 Z.RBRAPBG_PBGP_CODE                          SMR_BGP,
                 Z.RBRAPBC_AMT                                SMR_LICF,
                 Y.RBRAPBG_PBGP_CODE                          FAL_BGP,
                 Y.RBRAPBC_AMT                                FAL_LICF,
                 X.RBRAPBG_PBGP_CODE                          SPR_BGP,
                 X.RBRAPBC_AMT                                SPR_LICF,
                 ROBNYUD_VALUE_201                            ROANYUD_201,
                 ROBNYUD_VALUE_202                            ROANYUD_202,
                 ROBNYUD_VALUE_203                            ROANYUD_203,
                 ROBNYUD_VALUE_204                            ROANYUD_204,
                 ROBNYUD_VALUE_205                            ROANYUD_205,
                 ROBNYUD_VALUE_206                            ROANYUD_206,
                 ROBNYUD_VALUE_207                            ROANYUD_207,
                 ROBNYUD_VALUE_208                     ROANYUD_208,
                 ROBNYUD_VALUE_209                     ROANYUD_209,
                 ROBNYUD_VALUE_210                     ROANYUD_210,
                 ROBNYUD_VALUE_211                     ROANYUD_211,
                 ROBNYUD_VALUE_212                     ROANYUD_212,
                 ROBNYUD_VALUE_213                     ROANYUD_213,
                 ROBNYUD_VALUE_214                     ROANYUD_214,
                 ROBNYUD_VALUE_215                     ROANYUD_215,
                 ROBNYUD_VALUE_216                     ROANYUD_216,
                 ROBNYUD_VALUE_217                     ROANYUD_217,
                 ROBNYUD_VALUE_218                     ROANYUD_218,
                 ROBNYUD_VALUE_219                     ROANYUD_219,
                 ROBNYUD_VALUE_220                     ROANYUD_220,
                 ROBNYUD_VALUE_221                     ROANYUD_221,
                 ROBNYUD_VALUE_222                     ROANYUD_222,
                 ROBNYUD_VALUE_223                     ROANYUD_223,
                 ROBNYUD_VALUE_224                     ROANYUD_224,
                 ROBNYUD_VALUE_225                     ROANYUD_225,
                 ROBNYUD_VALUE_226                     ROANYUD_226,
                 ROBNYUD_VALUE_227                     ROANYUD_227,
                 ROBNYUD_VALUE_228                     ROANYUD_228,
                 ROBNYUD_VALUE_229                     ROANYUD_229,
                 ROBNYUD_VALUE_230                     ROANYUD_230,
                 ROBNYUD_VALUE_231                     ROANYUD_231,
                 ROBNYUD_VALUE_232                     ROANYUD_232,
                 ROBNYUD_VALUE_233                     ROANYUD_233,
                 ROBNYUD_VALUE_234                     ROANYUD_234,
                 ROBNYUD_VALUE_235                     ROANYUD_235,
                 ROBNYUD_VALUE_236                     ROANYUD_236,
                 ROBNYUD_VALUE_237                     ROANYUD_237,
                 ROBNYUD_VALUE_238                     ROANYUD_238,
                 ROBNYUD_VALUE_239                     ROANYUD_239,
                 ROBNYUD_VALUE_240                     ROANYUD_240
                 
            FROM SPRIDEN                 LEFT JOIN RORSTAT
                     ON     RORSTAT_PIDM = SPRIDEN_PIDM
                        AND RORSTAT_AIDY_CODE = :AIDY
                 LEFT JOIN SHRLGPA
                     ON     SHRLGPA_PIDM = SPRIDEN_PIDM
                        AND SHRLGPA_GPA_TYPE_IND = 'O'
                 LEFT JOIN RBRAPBG Z
                     ON     Z.RBRAPBG_PIDM = SPRIDEN_PIDM
                        AND Z.RBRAPBG_AIDY_CODE = :AIDY
                        AND Z.RBRAPBG_RUN_NAME = 'ACTUAL'
                        AND Z.RBRAPBG_PERIOD = :SMR
                 LEFT JOIN RBRAPBG Y
                     ON     Y.RBRAPBG_PIDM = SPRIDEN_PIDM
                        AND Y.RBRAPBG_AIDY_CODE = :AIDY
                        AND Y.RBRAPBG_RUN_NAME = 'ACTUAL'
                        AND Y.RBRAPBG_PERIOD = :FAL
                 LEFT JOIN RBRAPBG X
                     ON     X.RBRAPBG_PIDM = SPRIDEN_PIDM
                        AND X.RBRAPBG_AIDY_CODE = :AIDY
                        AND X.RBRAPBG_RUN_NAME = 'ACTUAL'
                        AND X.RBRAPBG_PERIOD = :SPR
                 LEFT JOIN RBRAPBC Z
                     ON     Z.RBRAPBC_PIDM = SPRIDEN_PIDM
                        AND Z.RBRAPBC_AIDY_CODE = :AIDY
                        AND Z.RBRAPBC_RUN_NAME = 'ACTUAL'
                        AND Z.RBRAPBC_PBTP_CODE = 'COA'
                        AND Z.RBRAPBC_PERIOD = :SMR
                        AND Z.RBRAPBC_PBCP_CODE = 'LICF'
                 LEFT JOIN RBRAPBC Y
                     ON     Y.RBRAPBC_PIDM = SPRIDEN_PIDM
                        AND Y.RBRAPBC_AIDY_CODE = :AIDY
                        AND Y.RBRAPBC_RUN_NAME = 'ACTUAL'
                        AND Y.RBRAPBC_PBTP_CODE = 'COA'
                        AND Y.RBRAPBC_PERIOD = :FAL
                        AND Y.RBRAPBC_PBCP_CODE = 'LICF'
                 LEFT JOIN RBRAPBC X
                     ON     X.RBRAPBC_PIDM = SPRIDEN_PIDM
                        AND X.RBRAPBC_AIDY_CODE = :AIDY
                        AND X.RBRAPBC_RUN_NAME = 'ACTUAL'
                        AND X.RBRAPBC_PBTP_CODE = 'COA'
                        AND X.RBRAPBC_PERIOD = :SPR
                        AND X.RBRAPBC_PBCP_CODE = 'LICF'
                 LEFT JOIN SGBSTDN ON SGBSTDN_PIDM = SPRIDEN_PIDM
                 LEFT JOIN ROBNYUD ON SPRIDEN_PIDM = ROBNYUD_PIDM
           WHERE     SPRIDEN_CHANGE_IND IS NULL
                 AND SGBSTDN_TERM_CODE_EFF =
                     (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                        FROM SGBSTDN A
                       WHERE     A.SGBSTDN_PIDM = SPRIDEN_PIDM
                             AND A.SGBSTDN_STST_CODE = 'AS'
                             AND A.SGBSTDN_TERM_CODE_EFF <= :FAL)
                 AND SGBSTDN_STST_CODE = 'AS'
                 AND SGBSTDN_MAJR_CODE_1 IN ('NRST',
                                             'PPTA',
                                             'RADT',
                                             'OTA',
                                             'C159',
                                             'RT',
                                             'C617',
                                             'C828',
                                             'ECDE',
                                             'MCED',
                                             'HEM',
                                             'ATTR',
                                             'CHED',
                                             'EXSC',
                                             'SPA',
                                             'ECIS',
                                             'VTEC',
                                             'BSW',
                                             'ESCI',
                                             'IMTH',
                                             'INLA',
                                             'INSS',
                                             'ISCI',
                                             'LFSC',
                                             'LSCM',
                                             'PHSC',
                                             'SHED',
                                             'SPED'))
   WHERE     1 = 1
         AND FALL_TMST IN ('LH',
                           'HT',
                           '3Q',
                           'FT')
ORDER BY 3
