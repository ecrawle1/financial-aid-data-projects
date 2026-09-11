# Privacy / FERPA-Oriented Audit — Group 08

> This is a privacy/PII code review for public-source preparation, not a legal determination of FERPA compliance.

Files reviewed: **20**

Risk summary: **High: 8**, **Medium: 11**, **Low: 1**

Key validation:
- No hard-coded 9-digit student/SSN literals remain in the sanitized SQL.
- No literal personal email addresses were found.
- The hard-coded internal PIDM exclusion in `SFA_DATA_BALANCE_APPEND.sql` was replaced with `:EXCLUDED_PIDM`.
- Direct SSN output was removed from both Second Chance Pell reports and `SFA_DATA_BALANCE_APPEND.sql`.
- Phone/email/address/free-text/staff-user output was removed where present and not necessary for public examples.
- Parentheses are balanced after ignoring comments/string literals; no obvious dangling SELECT-list commas were detected.
- SQL was **not executed against Oracle**, so this is structural/privacy review rather than runtime validation.

| File | Risk | Finding / sanitization |
|---|---|---|
| ROIDISB_applicant_has_holds.sql | Medium | Direct student ID/name plus hold reason and staff user ID in report output; removed direct identifiers and staff user output. |
| RTST_STATUS_N_BEFORE_FREEZE_UPDATED_022324.sql | Medium | Direct student ID/name with course/status history; public output now omits student identifiers and author name. |
| SAP Approvals with IS records.sql | Medium | Direct student ID/name with SAP, program, degree, and enrollment status; identifiers removed from public output. |
| SCH Fund Master List.sql | Low | Fund-level metadata and aggregate counts; no direct student identifiers in output. |
| Schell Loan Audit Info.sql | High | Student ID/name, full postal address, GPA, earned hours, and loan payment history combined in one report; direct identity/address output removed. |
| SCHELL Monthly report 041124.sql | High | Student ID/name combined with loan requirements, paid/accepted amounts, GPA, enrollment, SAP, and residency; direct identifiers removed. |
| Schell Report Request.sql | Medium | Direct student ID/name with program and loan requirement completion statuses; identifiers removed. |
| Scholarship Not KC Report.sql | Medium | Direct PIDM/ID/name with scholarship, enrollment, consortium, hold/appeal and payment data; identifying output removed and staff name in comment generalized. |
| Second Chance Pell Annual Report _ REVISIONS - 121124.sql | High | Federal reporting query directly returned Banner ID, SSN, and student name with detailed aid/program data; direct identity/SSN output removed. |
| Second Chance Pell Annual Report.sql | High | Federal reporting query directly returned Banner ID, SSN, and student name with detailed aid/cost data; direct identity/SSN output removed. |
| SEDPUX Status.sql | Medium | Direct student ID/name with verification requirement status; identifiers removed. |
| SFA_DATA_BALANCE_APPEND.sql | High | Direct ID/name/SSN plus phone, email, state, free-text comments, staff user IDs, holds and financial data; direct contact/identity/free-text/staff output removed and hard-coded PIDM parameterized. |
| SFS OR SMFL_NO TO SMR LOANS.sql | Medium | Direct student ID/name with aid period, loan response and loan amounts; identifiers removed. |
| SMFLSP aid paid 202360.sql | Medium | Direct student ID/name with aid, loan, requirement and hold data; identifiers removed and positional ORDER BY updated. |
| SMFLSP no loans paid 202360.sql | Medium | Direct student ID/name with aid, requirement and hold data; identifiers removed and positional ORDER BY updated. |
| SMFSP needs reviewed 061625.sql | High | Direct student ID/name plus SAI, loan amounts, free-text RHRCOMM, staff user ID and SAP data; direct identity/free-text/staff output removed. |
| SMRDLR_report_041525.sql | Medium | Direct student ID/name with packaging, SAP, program, enrollment and loan offer data; identifiers removed. |
| SOAPCOL Like B or NB with FAFSA 103017.sql | Medium | Direct student ID/name with degree history, SAP, enrollment and FAFSA status; identifiers removed. |
| SOR_Loan_CALC_Review_051326(3).sql | High | Direct student ID/name in a detailed loan eligibility/recommendation report with SAI, aggregate limits, lifetime usage and award amounts; final public output omits direct identifiers. |
| Spring OFRD Text em all.sql | High | Student phone numbers, Banner ID and names were the direct output for a text-message list; public version returns only an eligible-student count. |
