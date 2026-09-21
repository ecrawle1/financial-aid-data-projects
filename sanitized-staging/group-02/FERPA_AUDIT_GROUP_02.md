# FERPA / Privacy Audit — Group 02

Scope: 20 uploaded SQL files. Review covered hard-coded values, comments, direct identifiers in report output, free-text fields, and unique record identifiers.

## Key findings

- **Four hard-coded SSNs were found in one SQL file and removed.** They were replaced with bind variables; the values are not reproduced in this audit.
- **One hard-coded 9-digit student identifier was found in a SQL comment and removed.**
- Multiple queries selected student ID, name, birth date, SSN, loan number, or other direct identifiers. Public copies were adjusted to omit those fields from report output while retaining internal schema references needed for joins/comparisons.
- Aggregate-only reports were retained with minimal changes.
- No email addresses, passwords, API keys, or database credentials were detected in this batch.

## File-by-file audit

See the downloadable audit package for the full table of file-level changes.