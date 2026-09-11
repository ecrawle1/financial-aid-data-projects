# FERPA / Privacy Audit — Group 07

Files reviewed: 20
Risk summary: Critical: 1, High: 9, Medium: 8, Low: 2

| File | Risk | Finding |
|---|---|---|
| Pell edit 178.sql | Medium | Direct student ID/name output removed. |
| Pending Grad PLUS admitted 202660.sql | High | Student ID/name, internal PIDM output, and PLUS application ID removed from public output. |
| Plus and Grad Loan Origination Status = U Endorser Amount not null.sql | High | Student ID/name and borrower identifier removed; endorsement/origination logic retained. |
| PLUS Loan Reminder Email list.sql | High | Student ID/name plus parent borrower email/first name removed from output. |
| Plus Loans with No Borrower ID.sql | Medium | Student identifiers, borrower ID field, and loan number removed from output; null borrower-ID test retained. |
| Plus Loans with U Default Code.sql | High | Student ID/name removed from output containing default-status information. |
| Post Screen After NSLDS Req Date.sql | High | Student ID/name, SSN, and birth date removed from NSLDS/post-screen output. |
| Private Loan Authorization issues.sql | High | Student ID/name removed from private-loan authorization/financial output. |
| Private Loan non-matching.sql | High | Borrower name, DOB, and SSN removed from private-loan matching output. |
| Prvt loan No FAFSA - 062520.sql | High | Student ID/name, borrower name, and CommonLine unique ID removed from output. |
| PVT Loan Balance Due.sql | Critical | 132 hard-coded Banner-ID occurrences (129 unique) removed and replaced with bind input; ID/name output removed. |
| PVT Loan Reminder Email list.sql | Medium | Student ID/name output removed; public version returns only cohort count while retaining set-selection logic. |
| Regional and KC Hours.sql | Medium | Student ID/name removed from enrollment-hours output. |
| Regional not coming.sql | Medium | Student ID/name removed from admission/non-coming aid review output. |
| Rejected Loans.sql | High | Student ID/name and unique loan ID removed; positional ORDER BY adjusted. |
| Reprocessed ISIR Review.sql | Medium | Student ID/name removed from reprocessed-ISIR review output; internal PIDM retained for joins. |
| Required Hours.sql | Low | Fund-level configuration query; no student-level identifiers detected. RFRCOMM text retained because it is fund configuration, not student commentary. |
| RLADLOR YIC_6_062326.sql | Medium | Student ID/name removed; loan YIC/status comparison retained. |
| ROAMESG Master List.sql | Low | Reference-table message-code query; no student-level data detected. |
| ROAUSDF 301 and 302.sql | Medium | Student ID/name removed from user-defined-field output. |
