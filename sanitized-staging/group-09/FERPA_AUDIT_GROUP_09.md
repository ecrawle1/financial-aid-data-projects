# Privacy / FERPA-Oriented Audit — Group 09

> This is a privacy/PII code review for public-source preparation, not a legal determination of FERPA compliance.

Files reviewed: **13**

Risk summary: **High: 7**, **Medium: 5**, **Low: 1**, **Critical: 0**

Key validation:
- No hard-coded 9-digit student/SSN literals were present in the source files, and none remain in sanitized SQL.
- No literal personal email addresses were found.
- Raw SSN output was removed from `SSCARD Report.sql`, `V4V5 2526.sql`, and `V4V5 2627.sql`.
- Borrower SSN/name/DOB output was removed from `SUPVL Batch Report.sql`.
- Banner/FAFSA address fields were removed from `V4V5 Virtual Appt Indicator.sql`; the derived decision logic remains.
- Unique private-loan identifiers were removed from `SUPVL APP AMT VS AWARD AMT.sql`.
- Parentheses are balanced after ignoring comments/string literals; no obvious dangling SELECT-list commas were detected.
- SQL was **not executed against Oracle**, so this is structural/privacy review rather than runtime validation.
