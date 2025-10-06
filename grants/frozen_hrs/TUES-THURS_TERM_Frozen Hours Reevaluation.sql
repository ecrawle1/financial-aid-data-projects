SELECT BID,
       FNAME,
       LNAME,
       FROZEN_CR_HRS,
       FROZEN_ADJ,
       FROZEN_TMST,
       RORENRL_CONSORTIUM_IND,
       BILLED_HRS,
       PELL_OFFER,
       PELL_PAID,
       Pell_Lock_Ind,
       TEACH,
       TEACH_OFFER,
       TEACH_PAID,
       GPNM_ROAMESG,
       GPNF_ROAMESG,
       GPNS_ROAMESG,
       RORENRL_USER_ID
       
  FROM (SELECT SPRIDEN_ID                                  BID,
               SPRIDEN_FIRST_NAME                          FNAME,
               SPRIDEN_LAST_NAME                           LNAME,
               RORENRL_FINAID_CREDIT_HR                    FROZEN_CR_HRS,
               RORENRL_FINAID_ADJ_HR                       FROZEN_ADJ,
               
               CASE
                   WHEN RORENRL_FINAID_ADJ_HR >= 12 THEN 'FT'
                   WHEN RORENRL_FINAID_ADJ_HR >= 9 THEN '3Q'
                   WHEN RORENRL_FINAID_ADJ_HR >= 6 THEN 'HT'
                   WHEN RORENRL_FINAID_ADJ_HR >= 1 THEN 'LH'
               END                                         FROZEN_TMST,
               
               RORENRL_CONSORTIUM_IND,
               
               (SELECT SUM (SFRSTCR_BILL_HR)
                  FROM SFRSTCR
                 WHERE     SFRSTCR_TERM_CODE = :TERM
                       AND RORENRL_PIDM = SFRSTCR_PIDM)    BILLED_HRS,
                       
               A.RPRATRM_OFFER_AMT                         PELL_OFFER,
               A.RPRATRM_PAID_AMT                          PELL_PAID,
               A.RPRATRM_LOCK_IND                          Pell_Lock_Ind,
               B.RPRATRM_FUND_CODE                         TEACH,
               B.RPRATRM_OFFER_AMT                         TEACH_OFFER,
               B.RPRATRM_PAID_AMT                          TEACH_PAID,
               D.RORMESG_MESG_CODE                         GPNM_ROAMESG,
               E.RORMESG_MESG_CODE                         GPNF_ROAMESG,
               F.RORMESG_MESG_CODE                         GPNS_ROAMESG,
               RORENRL_USER_ID
          
          FROM RORENRL
               LEFT JOIN SPRIDEN
                   ON     RORENRL_PIDM = SPRIDEN_PIDM
                      AND SPRIDEN_CHANGE_IND IS NULL
                      
               LEFT JOIN RPRATRM A
                   ON     RORENRL_PIDM = A.RPRATRM_PIDM
                      AND RORENRL_TERM_CODE = A.RPRATRM_PERIOD
                      AND A.RPRATRM_FUND_CODE = 'GFNPEL'
                      
               LEFT JOIN RPRATRM B
                   ON     RORENRL_PIDM = B.RPRATRM_PIDM
                      AND RORENRL_TERM_CODE = B.RPRATRM_PERIOD
                      AND B.RPRATRM_FUND_CODE IN ('GFUTGU', 'GFUTU1')
                      
               LEFT JOIN RORMESG D
                   ON     RORENRL_PIDM = D.RORMESG_PIDM
                      AND D.RORMESG_AIDY_CODE = :AIDY
                      AND D.RORMESG_MESG_CODE = 'GPNM'
                      
               LEFT JOIN RORMESG E
                   ON     RORENRL_PIDM = E.RORMESG_PIDM
                      AND E.RORMESG_AIDY_CODE = :AIDY
                      AND E.RORMESG_MESG_CODE = 'GPNF'
                      
               LEFT JOIN RORMESG F
                   ON     RORENRL_PIDM = F.RORMESG_PIDM
                      AND F.RORMESG_AIDY_CODE = :AIDY
                      AND F.RORMESG_MESG_CODE = 'GPNS'
                      
         WHERE RORENRL_TERM_CODE = :TERM AND RORENRL_ENRR_CODE = 'REPEAT'--and RORENRL_USER_ID in ('LRODIG5','AGEE', 'ABAUDO')
                                                                         )
                                                                         
    -- Find when student's frozen hours time stamp does not match their actual registered hours time stamp
    WHERE (FROZEN_TMST = '3Q' AND BILLED_HRS > 11)
       OR (FROZEN_TMST = 'HT' AND BILLED_HRS > 8)
       OR (FROZEN_TMST = 'LH' AND BILLED_HRS > 5)
