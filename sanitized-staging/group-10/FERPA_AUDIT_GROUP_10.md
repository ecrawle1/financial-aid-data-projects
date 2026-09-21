# Privacy / FERPA-Oriented Audit — Group 10

> This is a privacy/PII code review for public-source preparation, not a legal determination of FERPA compliance.

Files reviewed: **20**

Risk summary: **High: 11**, **Medium: 9**, **Low: 0**, **Critical: 0**

Key validation:
- Two literal Banner IDs found in a developer comment were removed.
- No hard-coded 9-digit student/SSN literals remain in the sanitized SQL.
- No literal personal email addresses remain.
- Direct SSN/DOB output was removed from NSLDS, PLUS, suspense/match-review, and unusual-enrollment reports.
- Unique loan/application identifiers, free-text comments, and staff user IDs were removed from public output where applicable.
- Parentheses are balanced after ignoring comments/string literals; no obvious dangling SELECT-list commas were detected.
- SQL was **not executed against Oracle**, so this is structural/privacy review rather than runtime validation.

Highest-risk files include `2627 NSLDS Tracking Requirements.sql`, `2627 PLUS REPORT.sql`, `2627 PVT Loan Not Awarded.sql`, `2627 Potentially Underawarded Sub.sql`, `2627 Unusual Enrollment.sql`, and the three suspense/match-review queries because the originals combined direct identity with SSN, DOB, borrower, federal-aid, or uniquely identifying loan/application data.
