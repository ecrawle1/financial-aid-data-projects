# FERPA / Privacy Audit — Group 03

Reviewed 20 SQL files for hard-coded student data, direct identifiers, sensitive contact information, free-text comments, and other privacy risks before public GitHub staging.

## Summary

- Critical: 2
- High: 6
- Medium: 12
- Low: 0

### Embedded data findings

- `COVCOD recon.sql`: removed 463 hard-coded Banner-ID occurrences representing 399 unique IDs.
- `FAFSA ON FILE.sql`: removed 107 hard-coded Banner IDs.
- `DL count have begun courses.sql`: removed one hard-coded Banner ID from a commented test filter.
- `Corrections & ISIRS Loaded by day - Banner & Suspends.sql`: generalized hard-coded employee account usernames to bind variables (not FERPA, but unsuitable for public source).

The sanitized public copies remove direct student identifiers from report output where practical and preserve internal schema references only where needed for joins, filters, or comparison logic.
