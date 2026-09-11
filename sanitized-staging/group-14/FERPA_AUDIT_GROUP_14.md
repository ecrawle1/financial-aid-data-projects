# Privacy / FERPA-Oriented Audit — Group 14

Files reviewed: **20**

Risk summary: **Critical: 1**, **High: 14**, **Medium: 5**, **Low: 0**

## Key findings

- `1X-TERM_Study Abroad Part 1.sql` contained an active list of **33 hard-coded nine-digit student IDs**. The public version removes the literal list and uses `:STUDENT_ID` instead.
- Three additional nine-digit student/test IDs found in comments were parameterized.
- Several reports combined student identity with SSN/tax ID, DOB, award/payment information, SAI/EFC, verification/SAP data, or OCOG eligibility calculations. Direct identity output was removed or masked.
- Individualized RHRCOMM free-text output and staff award-user output were removed where applicable.
- No hard-coded nine-digit student/SSN literals remain in the sanitized SQL.
- No literal personal email addresses were found.
- Executable parentheses are balanced after ignoring comments/string literals, and no obvious dangling SELECT-list commas were detected.
- SQL was **not executed against Oracle**, so this is structural/privacy validation rather than runtime testing.

## Risk counts

- Critical — 1
- High — 14
- Medium — 5
- Low — 0

This review is intended for public-source preparation and is not a legal determination of FERPA compliance.
