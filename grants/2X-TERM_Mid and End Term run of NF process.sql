SELECT DISTINCT BID,
                FNAME,
                LNAME,
                ND_CRN,
                ND_STATUS_MESS,
                ND_CREDIT_HRS,
                ND_BILLED_HRS,
                ND_ACTIVITY_DATE,
                ND_STATUS_CODE,
                NF_CRN,
                NF_STATUS_MESS,
                NF_CREDIT_HRS,
                NF_BILLED_HRS,
                NF_ACTIVITY_DATE,
                NF_STATUS_CODE,
                CREDIT_HRS,
                BILLED_HRS,
                KC_BILL_TOTAL,
                NON_KC_BILL_TOTAL,
                CASE WHEN KC_BILL_TOTAL < NON_KC_BILL_TOTAL
                AND OCOG IN ('GSNOCG', 'GSN02E')
                THEN 'Y' 
                END AS REVIEW_OCOG,
                PELL,
                PELL_STATUS,
                OCOG,
                OCOG_STATUS,
                GPNM_MESG,
                GPNM_DESC,
                GPNF_MESG,
                GPNF_DESC,
                GPNS_MESG,
                GPNS_DESC,
                IPNM_MESG,
                IPNM_DESC,
                IPNF_MESG,
                IPNF_DESC,
                IPNS_MESG,
                IPNS_DESC
                
  FROM (SELECT DISTINCT SPRIDEN_ID                    BID,
               SPRIDEN_FIRST_NAME            FNAME,
               SPRIDEN_LAST_NAME             LNAME,
               SFRSTCA_TERM_CODE,
               
               (SELECT SFRSTCR_CRN
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'ND')     ND_CRN,
               
               (SELECT SFRSTCR_MESSAGE
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'ND')     ND_STATUS_MESS,
               
               (SELECT SFRSTCR_CREDIT_HR
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'ND')     ND_CREDIT_HRS,
               
               (SELECT SFRSTCR_BILL_HR
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'ND')     ND_BILLED_HRS,
               
               
               (SELECT SFRSTCR_ACTIVITY_DATE
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'ND')     ND_ACTIVITY_DATE,
               
               (SELECT SFRSTCR_RSTS_CODE 
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'ND')     ND_STATUS_CODE,
               
               (SELECT SFRSTCR_CRN 
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'NF')     NF_CRN,
               
               (SELECT SFRSTCR_MESSAGE  
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'NF')     NF_STATUS_MESS,
               
               (SELECT SFRSTCR_CREDIT_HR      
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'NF')     NF_CREDIT_HRS,
               
               (SELECT SFRSTCR_BILL_HR         
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'NF')     NF_BILLED_HRS,
               
               (SELECT SFRSTCR_ACTIVITY_DATE     
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'NF')     NF_ACTIVITY_DATE,
               
               (SELECT SFRSTCR_RSTS_CODE      
               FROM SFRSTCR
               WHERE SFRSTCR_PIDM = SFRSTCA_PIDM
               AND SFRSTCR_CRN = SFRSTCA_CRN
               AND SFRSTCR_RSTS_CODE = 'NF')     NF_STATUS_CODE,

               (SELECT SUM (SFRSTCR_CREDIT_HR)
                  FROM SFRSTCR
                 WHERE     SFRSTCA_PIDM = SFRSTCR_PIDM
                       AND SFRSTCA_TERM_CODE = SFRSTCR_TERM_CODE)  CREDIT_HRS,
                   
               (SELECT SUM (SFRSTCR_BILL_HR)
                  FROM SFRSTCR
                 WHERE     SFRSTCA_PIDM = SFRSTCR_PIDM
                       AND SFRSTCA_TERM_CODE = SFRSTCR_TERM_CODE)  BILLED_HRS,
                   
               P.RPRATRM_FUND_CODE             PELL,
               P.RPRATRM_AWST_CODE             PELL_STATUS,
               O.RPRATRM_FUND_CODE             OCOG,
               O.RPRATRM_AWST_CODE             OCOG_STATUS,
               
               (SELECT SUM (SFRSTCR_BILL_HR)
                  FROM SFRSTCR
                 WHERE     SFRSTCR_PIDM = SFRSTCA_PIDM
                       AND SFRSTCR_TERM_CODE = :TERM
                       AND SFRSTCR_CAMP_CODE = 'KC')                 KC_BILL_TOTAL,
                       
               (SELECT SUM (SFRSTCR_BILL_HR)
                  FROM SFRSTCR
                 WHERE     SFRSTCR_PIDM = SFRSTCA_PIDM
                       AND SFRSTCR_TERM_CODE = :TERM
                       AND SFRSTCR_CAMP_CODE <> 'KC')                 NON_KC_BILL_TOTAL,
                       
            B.RORMESG_MESG_CODE GPNM_MESG,
            B.RORMESG_FULL_DESC GPNM_DESC,
            C.RORMESG_MESG_CODE GPNF_MESG,
            C.RORMESG_FULL_DESC GPNF_DESC,
            D.RORMESG_MESG_CODE GPNS_MESG,
            D.RORMESG_FULL_DESC GPNS_DESC,
            E.RORMESG_MESG_CODE IPNM_MESG,
            E.RORMESG_FULL_DESC IPNM_DESC,
            F.RORMESG_MESG_CODE IPNF_MESG,
            F.RORMESG_FULL_DESC IPNF_DESC,
            G.RORMESG_MESG_CODE IPNS_MESG,
            G.RORMESG_FULL_DESC IPNS_DESC
                                   
          FROM SFRSTCA
              
               JOIN SPRIDEN
               ON SPRIDEN_PIDM = SFRSTCA_PIDM
               AND SPRIDEN_CHANGE_IND IS NULL
                            
               JOIN RPRATRM P
                      ON  SFRSTCA_PIDM = P.RPRATRM_PIDM
                      AND P.RPRATRM_PERIOD = :TERM
                      AND P.RPRATRM_FUND_CODE = 'GFNPEL'
                
                JOIN RPRATRM O
                      ON  SFRSTCA_PIDM = O.RPRATRM_PIDM
                      AND O.RPRATRM_PERIOD = :TERM
                      AND O.RPRATRM_FUND_CODE IN ('GSNOCG', 'GSNO2E')
                
                LEFT JOIN RORMESG B
                   ON B.RORMESG_PIDM = SFRSTCA_PIDM
                   AND B.RORMESG_AIDY_CODE = :AIDY
                   AND B.RORMESG_MESG_CODE = 'GPNM'
                   
                   LEFT JOIN RORMESG C
                   ON C.RORMESG_PIDM = SFRSTCA_PIDM
                   AND C.RORMESG_AIDY_CODE = :AIDY
                   AND C.RORMESG_MESG_CODE = 'GPNF'
                   
                   LEFT JOIN RORMESG D
                   ON D.RORMESG_PIDM = SFRSTCA_PIDM
                   AND D.RORMESG_AIDY_CODE = :AIDY
                   AND D.RORMESG_MESG_CODE = 'GPNS'
                   
                   LEFT JOIN RORMESG E
                   ON E.RORMESG_PIDM = SFRSTCA_PIDM
                   AND E.RORMESG_AIDY_CODE = :AIDY
                   AND E.RORMESG_MESG_CODE = 'IPNM'
                   
                   LEFT JOIN RORMESG F
                   ON F.RORMESG_PIDM = SFRSTCA_PIDM
                   AND F.RORMESG_AIDY_CODE = :AIDY
                   AND F.RORMESG_MESG_CODE = 'IPNF'
                   
                   LEFT JOIN RORMESG G
                   ON G.RORMESG_PIDM = SFRSTCA_PIDM
                   AND G.RORMESG_AIDY_CODE = :AIDY
                   AND G.RORMESG_MESG_CODE = 'IPNS'
                      
         WHERE     SFRSTCA_TERM_CODE = :TERM
               AND SFRSTCA_SOURCE_CDE = 'BASE')
               
               WHERE (ND_STATUS_CODE IS NOT NULL
               OR NF_STATUS_CODE IS NOT NULL)
ORDER BY 1,4
