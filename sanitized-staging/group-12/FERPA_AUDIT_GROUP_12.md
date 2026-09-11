# Privacy / FERPA-Oriented Audit — Group 12

> This is a privacy/PII code review for public-source preparation, not a legal determination of FERPA compliance.

Files reviewed: **19**

Risk summary: **High: 6**, **Medium: 12**, **Low: 1**, **Critical: 0**

Key validation:
- No hard-coded 9-digit student/SSN literals were found in the originals or remain in the sanitized SQL.
- No literal personal email addresses were found.
- Direct student ID/name output was removed where practical.
- Exact DOB output was removed from the selective-service scholarship report; derived age/status logic remains.
- Staff verification user output was removed from the taxable-income/verification report.
- The two filenames containing a staff member's first name were generalized for public use.
- Parentheses are balanced after ignoring comments/string literals; no obvious dangling SELECT-list commas were detected.
- SQL was **not executed against Oracle**, so this is structural/privacy review rather than runtime validation.

| Public file | Risk | Finding / sanitization | Repository group |
|---|---|---|---|
| SPBS04 Students.sql | Medium | Returned student ID/name with scholarship award amounts and major. Direct student identifiers removed. | banner-financial-aid-packaging-budget |
| SPMZCC WIP.sql | Medium | Returned student ID/name with multi-year scholarship award history. Direct student identifiers removed. | banner-financial-aid-packaging-budget |
| SPNU01 & SINU07 request.sql | Medium | Returned student ID/name with award offer/accept/paid amounts and dates. Direct student identifiers removed; ORDER BY changed to named fund field. | banner-financial-aid-packaging-budget |
| SPRC Info.sql | Medium | Returned student ID/name with residency, program, enrollment, budget, unmet-need, and aid information. Direct student identifiers removed; public filename generalized. | banner-financial-aid-packaging-budget |
| SPRC recalc.sql | Medium | Returned PIDM/ID/name with residency, program, budget, resource, unmet-need, and aid calculations. Direct identifiers removed from the BASE result; ORDER BY changed to non-identifying fields. | banner-financial-aid-packaging-budget |
| SSMTCS Paid.sql | Medium | Returned student ID/name with award and paid amounts/dates. Direct student identifiers removed; positional/name order changed. | banner-financial-aid-packaging-budget |
| State Scholarships with Selective Service Info.sql | High | Returned student ID/name, exact DOB, age, selective-service/compliance category, scholarship amounts, residency, and disbursement data. Direct identity and exact DOB removed; derived age/status logic retained. | banner-financial-aid-verification-sap |
| Student_Taxable_Income_Grant_Scholarship_Aid_091024.sql | High | Returned student ID/name with parent/student AGI, tax/IRS flags, marital status, grant/scholarship aid, verification status, and staff verification user. Direct student identifiers and staff user removed. | banner-financial-aid-verification-sap |
| Students with Merit Award Canceled in NF_SF_Course.sql | High | Returned student ID/name with course grades/registration status and merit scholarship offer/cancel/paid data. Direct identity removed from final output; internal identifiers retained only for joins/grouping. | banner-financial-aid-holds-enrollment |
| Students with Teach Cert answer.sql | Medium | Returned student ID/name with FAFSA education/career response and student-status information. Direct student identifiers removed. | banner-financial-aid-verification-sap |
| LF FGF Request.sql | High | Returned student ID/name with FISAP income and enrollment/cohort information. Direct student identifiers removed; public filename generalized. | banner-financial-aid-packaging-budget |
| Synthomer Request.sql | High | Returned student ID/name with high-school history, Pell EFC/eligibility, enrollment, and freshman status. Direct student identifiers removed. | banner-financial-aid-packaging-budget |
| Unmet Need STEM Proposal 030724.sql | Low | Final result is aggregate by campus/major/class with counts and averages. Student identifiers are used internally for aggregation only and are not returned in the final result. | banner-financial-aid-packaging-budget |
| WAIVERS OVER COST 2.sql | Medium | Returned PIDM/Banner ID with waiver, Pell, COA, other-aid and enrollment calculations. Direct identifiers removed from the result. | banner-financial-aid-packaging-budget |
| WAIVERS OVER COST WITH SUMMER LOANS.sql | High | Returned PIDM/Banner ID with waiver, summer-loan, COA, other-aid and enrollment calculations. Direct identifiers removed from the result. | banner-financial-aid-loans |
| WAIVERS OVER COST.sql | Medium | Returned student ID/name with waiver, Pell, COA and other-aid amounts. Direct student identifiers removed. | banner-financial-aid-packaging-budget |
| Waivers with Holds preventing disbursement.sql | Medium | Returned student ID/name with waiver award amounts and active hold/disbursement-prevention details. Direct student identifiers removed. | banner-financial-aid-holds-enrollment |
| Waivers with other aid.sql | Medium | Returned student ID/name with waiver and other-aid amounts. Direct student identifiers removed. | banner-financial-aid-packaging-budget |
| XDISS2 Students.sql | Medium | Returned student ID/name with student type/level/program and budget groups. Direct student identifiers removed. | banner-financial-aid-packaging-budget |
