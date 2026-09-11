# Privacy / FERPA-Oriented Audit — Group 13

> This is a privacy/PII code review for public-source preparation, not a legal determination of FERPA compliance.

Files reviewed: **15**

Risk summary: **High: 7**, **Medium: 8**, **Low: 0**, **Critical: 0**

Key validation:
- No hard-coded 9-digit student/SSN literals were found.
- No literal personal email addresses were found.
- Direct student ID/name output was replaced with non-identifying NULL placeholders where needed to preserve complex SELECT * structures.
- SSN, exact DOB, staff hold user, and student free-text comments were removed from the TS-hold report output.
- Parentheses are balanced after ignoring comments/string literals; no obvious dangling SELECT-list commas were detected.
- SQL was **not executed against Oracle**, so this is structural/privacy review rather than runtime validation.

| File | Risk | Finding / sanitization | Repository group |
|---|---|---|---|
| _Daily_AIDY_ Student with a TS Hold_SPRING ONLY.sql | High | Returned Banner ID, SSN, DOB, name, hold user, and student free-text comments with TS hold, Pell, transfer-monitoring and graduation data. Direct identity, staff user, and free-text comment output were replaced with NULL placeholders. | banner-financial-aid-holds-enrollment |
| _MONTHLY_SUM_less_half_yes_to_loan_SUMMER ONLY.sql | Medium | Returned student identity with loan eligibility/offer/accept/paid, enrollment/time-status, SAP and/or aggregate data. Direct student identity was removed from public output. | banner-financial-aid-loans |
| 1X-TERM Budget Component Manual Override.sql | Medium | Returned student identity with user-defined budget override indicators and budget component amounts. Direct student identity was removed. | banner-financial-aid-packaging-budget |
| 1X-TERM_Special Rate Codes and Virtual Programs.sql | Medium | Returned student identity with program/rate/residency, enrollment, budget, need and aid data. Direct student identity was removed. | banner-financial-aid-packaging-budget |
| TUESDAY_Dual Degree Rate Codes.sql | Medium | Returned student identity with program/rate/residency, enrollment, budget, need and aid data. Direct student identity was removed. | banner-financial-aid-packaging-budget |
| WEDNESDAY_ AIDY_LH Expected Enrollment and USDF SMR Loans.sql | Medium | Returned student identity with loan eligibility/offer/accept/paid, enrollment/time-status, SAP and/or aggregate data. Direct student identity was removed from public output. | banner-financial-aid-loans |
| _Daily_SMRDLR_Report_SUMMER ONLY.sql | High | Returned student identity with loan eligibility/offer/accept/paid, enrollment/time-status, SAP and/or aggregate data. Direct student identity was removed from public output. | banner-financial-aid-loans |
| 1X-TERM_TMST Override Quality Control.sql | Medium | Returned student identity with time-status, enrolled hours, SAP and user-defined override values. Direct student identity was removed. | banner-financial-aid-holds-enrollment |
| 1X-YEAR_License Fees .sql | Medium | Returned student identity with major, earned hours, budget/license-fee amounts and a broad set of user-defined values. Direct student identity was removed. | banner-financial-aid-packaging-budget |
| 1X-YEAR_Summer_Clean_Up_SUMMER ONLY.sql | High | Returned student identity with detailed summer aid categories, frozen/enrollment hours, packaging and requirement/status data. Direct student identity was removed. | banner-financial-aid-packaging-budget |
| MONDAY_AIDY_LH with Unpaid_Loans_TERM_FAL_TMST.sql | High | Returned student identity with loan eligibility/offer/accept/paid, enrollment/time-status, SAP and/or aggregate data. Direct student identity was removed from public output. | banner-financial-aid-loans |
| MONDAY_AIDY_LH with Unpaid_Loans_TERM_SMR_TMST.sql | High | Returned student identity with loan eligibility/offer/accept/paid, enrollment/time-status, SAP and/or aggregate data. Direct student identity was removed from public output. | banner-financial-aid-loans |
| MONDAY_AIDY_Loan Cleanup- NE_CUR_TERM_SMR_TMST.sql | High | Returned student identity with loan eligibility/offer/accept/paid, enrollment/time-status, SAP and/or aggregate data. Direct student identity was removed from public output. | banner-financial-aid-loans |
| MONDAY_AIDY_Loan Cleanup- NE_CUR_TERM-FAL_TMST.sql | High | Returned student identity with loan eligibility/offer/accept/paid, enrollment/time-status, SAP and/or aggregate data. Direct student identity was removed from public output. | banner-financial-aid-loans |
| MONDAY_TERM_Housing_Report.sql | Medium | Returned student identity with FAFSA/dependency, packaging, COA/need, housing charges/responses, requirements and award data. Direct student identity was removed from final output. | banner-financial-aid-packaging-budget |