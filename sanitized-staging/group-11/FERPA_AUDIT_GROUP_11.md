# Privacy / FERPA-Oriented Audit — Group 11

> This is a privacy/PII code review for public-source preparation, not a legal determination of FERPA compliance.

Files reviewed: **6**

Risk summary: **High: 2**, **Medium: 4**, **Critical: 0**, **Low: 0**

Key validation:
- No hard-coded 9-digit student/SSN literals were found in the originals or remain in the sanitized SQL.
- No literal personal email addresses were found.
- Direct phone and email output/retrieval logic was removed from the verification-status report.
- Direct student ID/name output was removed from all six public SQL files.
- Parentheses are balanced after ignoring comments/string literals; no obvious dangling SELECT-list commas were detected.
- SQL was **not executed against Oracle**, so this is structural/privacy review rather than runtime validation.

| File | Risk | Finding / sanitization |
|---|---|---|
| 2627 Verif Status Report.sql | High | Returned Banner ID/name, permanent and primary phone numbers, KSU email, and verification/SAI/SAP/enrollment data. Direct identity/contact fields and phone/email retrieval logic were removed. |
| 2627 Verif-FHCITC Cleared in prior year.sql | High | Returned student ID/name with current and prior-year citizenship-document requirement/status history. Direct student identifiers were removed. |
| 202510 Proration Verification.sql | Medium | Returned student ID/name with packaging, degree/proration, and enrollment data. Direct student identifiers were removed. |
| 202560 Proration Verification.sql | Medium | Returned student ID/name with packaging, degree/proration, dependency, SAP, enrollment, verification and NSLDS status data. Direct student identifiers were removed. |
| 202610 Proration Verification.sql | Medium | Returned student ID/name with packaging, degree/proration, dependency, SAP, enrollment, verification and NSLDS status data. Direct student identifiers were removed. |
| 202660 Proration Verification.sql | Medium | Returned student ID/name with packaging, degree/proration, dependency, SAP, enrollment, verification and NSLDS status data. Direct student identifiers were removed. |
