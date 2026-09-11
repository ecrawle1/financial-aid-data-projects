# FERPA Audit – SQL Group 04

This audit covers 20 uploaded SQL files. Public copies were sanitized before GitHub staging.

## Severity summary

- Critical: 5
- High: 5
- Medium: 10

## Critical findings

- `FFD.sql`: 285 literal Banner/student IDs removed and replaced with bind placeholders.
- `FISAP - check students that error for paid aid.sql`: 86 literal Banner/student IDs removed and replaced with bind placeholders.
- `Has Fed Loan_any status.sql`: 926 literal Banner/student IDs removed and replaced with bind placeholders.
- `Has Fed Loan_PAID.sql`: 926 literal Banner/student IDs removed and replaced with bind placeholders.
- `ID lookup using SSNs from list.sql`: 284 SSN occurrences (271 unique) removed and replaced with bind placeholders; SSN and identity fields removed from public output.

## High findings

- `Grad Student GPA SAP Report.sql`: hard-coded student test ID removed; identity fields removed from public output.
- `GE_FVT.sql`: SSN, Banner ID, and student name removed from public output.
- `GE_FVT_Student_Cohort.sql`: SSN, Banner ID, and student name removed from public output.
- `Great Minds data by term.sql`: SSN and Banner ID removed from public output.
- `I Promise Tuition Adjustments.sql`: direct identifiers and free-text RHRCOMM comment content removed from public output.

Other files contained student-identifying output fields but no literal student data. Those public outputs were de-identified. No passwords, API keys, connection strings, or literal personal email addresses were found.
