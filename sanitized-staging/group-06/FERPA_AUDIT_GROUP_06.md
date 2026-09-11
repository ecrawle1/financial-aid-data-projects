# FERPA Audit — Group 06

Files reviewed: 20
Risk summary: Critical: 2, High: 7, Medium: 11

Sanitization standard: literal student identifiers removed or parameterized; direct student/borrower identifiers removed from public result sets where practical; individualized free-text and direct email output removed; schema fields retained internally when needed for query logic.

| File | Risk | Finding |
|---|---|---|
| NEALP with Additional Info.sql | Critical | 95 hard-coded SSNs; direct student identifiers in output |
| NSLDSR or NSLDSA status of C.sql | Critical | 467 hard-coded student-ID occurrences representing 464 unique students |
| NON-CITIZEN REVIEW.sql | High | direct student identifiers plus alien registration number/citizenship matching data |
| NR-NF-SF-W- with FED Loans and SFASTCA and final grade appended.sql | High | 7 unique hard-coded student IDs in comments; direct identifiers, grades, registration messages, and RHRCOMM free text |
| NSLDS Tracking Requirements NOT CLEARED_081925.sql | High | student ID/name/SSN/DOB, email, and free-text RHRCOMM output |
| NSLDSD Cleared with New Default Status.sql | High | direct student identifiers, SSN, and birth date in report output |
| OGSLSV Recon.sql | High | direct student identifiers combined with selective-service/compliance attributes |
| OKR Private Loan Tracking report.sql | High | student and borrower names plus borrower SSN in report output |
| OVERAWARD REPORT.sql | High | direct identifiers plus free-text applicant comments/staff user ID with detailed aid/need data |
| Missing Rejects 042518.sql | Medium | direct student identifiers and loan identifier in report output |
| NON FRESHMAN.sql | Medium | direct student identifiers in report output |
| NOT GRAD_RPT.sql | Medium | direct student identifiers in report output |
| NSLDSC_COMMENT_CODES.sql | Medium | direct student identifiers in report output |
| OC or ON Hold Need Expired.sql | Medium | direct student identifiers and internal PIDM exposed in final result |
| Packaged at FT, need adjustment.sql | Medium | direct student identifiers in report output |
| Packaged with Subsequent Current ISIR.sql | Medium | direct student identifiers with ISIR/SAI and verification data |
| packaging validation.sql | Medium | direct student identifiers with packaging/budget/SAI data |
| Packaging Validation_2526.sql | Medium | direct student identifiers with detailed packaging/budget data |
| Parent or Grad PLUS admitted 202660, not disbursed.sql | Medium | direct student identifiers in admission/PLUS-loan report output |
| PCKGED 040225_NO LOANS.sql | Medium | direct student identifiers in packaging/enrollment/SAP report output |

## Validation

- No quoted 9-digit student/SSN literals remain in the sanitized SQL files.
- No literal personal email addresses were detected.
- No passwords, API keys, or connection strings were detected.
- Parenthesis balance and basic malformed-select checks passed for all sanitized files.
- SQL was not executed against Oracle; runtime/database validation is still required before operational use.
