# Sanitized SQL — Group 14

This batch contains 20 SQL reports reviewed for public-code staging.

Privacy review highlights:
- Direct student identifiers, SSNs/DOBs, personal email output, individualized free-text comments, and staff user identifiers were removed or masked where practical.
- An active Study Abroad filter containing 33 hard-coded nine-digit student IDs was removed and parameterized.
- Three additional nine-digit test/student IDs found in comments were parameterized.
- Schema fields may remain internally when required for joins, filtering, calculations, or comparison logic.

Do not commit query outputs, exports, screenshots, or student-level data.

See `FERPA_AUDIT_GROUP_14.md` for the batch audit. This is a privacy/PII review, not a legal determination of FERPA compliance.
