# FERPA / PII Audit — Group 01

## Summary

- Files reviewed: **20**
- Hard-coded 9-digit numeric identifiers detected: **0**
- SSN-formatted literal values detected: **0**
- Personal email literal values detected: **0**
- Name-like personal literal values detected: **0**
- Sanitization approach: direct identifiers were removed from the **final result sets** while preserving joins and internal comparison logic where those fields are necessary to make the SQL function.

## High-risk source queries

- `_2627 VERIF MERGE FILE.sql` selected student, parent, and spouse names, SSNs, and birth dates.
- `2526 NSLDS Tracking Requirements.sql` selected student ID/name, SSN, birth date, institutional email, and free-text comments.
- `2526 PLUS WORKING-NEW.sql` selected student/borrower names, SSNs, birth dates, borrower email, and application identifiers.
- `2526 PVT Loan Not Awarded.sql` selected student ID/name/DOB and a private-loan application identifier.
- `2526 Disbursement Error Report.sql` selected student identifiers, loan number, and free-text fund comments.
- `2526 RLADLOR RPAAWRD Discrepancies.sql` selected student identifiers and loan number.

All remaining files in this batch selected a student ID and/or student name in their result set; those identifiers were removed in the public copies.

## Important limitation

This review determines whether the **SQL source text itself** contains or directly returns obvious identifiers. It does not make student-level query output non-FERPA data. Financial aid, enrollment, SAP, transcript, FAFSA, NSLDS, and award information can still be protected education-record data when a query is run against production data. Never publish query results or screenshots containing real records.
