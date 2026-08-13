# Alert Triage Report — SQL Injection Attempt

## Summary

| Field                | Value |
|-----------------------|-------|
| Alert / Rule ID        | 100020 |
| Rule Name              | Possible SQL Injection attempt detected in web access log |
| Date / Time (UTC)      | *2026-0X-XX 15:10:42* |
| Severity (Wazuh level) | 12 (High) |
| MITRE ATT&CK Technique | T1190 — Exploit Public-Facing Application |
| Source IP              | 192.168.56.30 (attacker/Kali) |
| Destination IP / Host  | 192.168.56.20:80 (DVWA / Apache) |
| Analyst                | *your name* |
| Status                 | Closed — Confirmed (simulated) |

## Alert Details

```
rule.id: 100020
rule.description: Possible SQL Injection attempt detected in web access log
data.srcip: 192.168.56.30
full_log: 192.168.56.30 - - [XX/Aug/2026:15:10:42] "GET /dvwa/vulnerabilities/sqli/?id=1%27+UNION+SELECT+user%2Cpassword+FROM+users--+-&Submit=Submit HTTP/1.1" 200 4211
```

## What happened (analysis)

Manual SQL injection payloads were sent against DVWA's SQLi vulnerability
page: first a tautology-based auth bypass (`' OR '1'='1`), then a UNION-based
enumeration attempt targeting the `users` table (`UNION SELECT user,
password FROM users-- -`). Wazuh's regex against parsed Apache access logs
matched the `UNION SELECT` and `--` tokens in the request URL, firing rule
`100020` on the base web-attack rule `31100`.

The HTTP 200 response code combined with a larger-than-baseline response
size (`4211` bytes vs. a typical error page) is a strong secondary indicator
that the UNION query executed successfully and returned data — this should
be manually verified by checking the actual response body from DVWA.

## Evidence

- Screenshot: `../screenshots/sqli-alert.png`
- Screenshot: `../screenshots/dvwa-response-body.png` (showing leaked
  user/password hashes from the UNION query, if confirmed)

## Impact assessment

If successful, this technique would allow full enumeration of the DVWA
`users` table, including password hashes — a critical data exposure. In a
real environment this is a **confirmed data breach**, not just an attempt,
if the response body shows returned records.

## False positive considerations

Legitimate application traffic containing SQL-like keywords (e.g. a support
form where a user pastes an actual SQL error message, or a search feature
querying content that happens to include words like "union" or "select") could
theoretically trigger this rule. To rule out: review the full request
parameters for a coherent injection pattern (quote characters, comment
terminators, boolean logic) rather than isolated keyword matches, and check
whether the response indicates a database error or unusual data volume.

## Response actions taken

- [x] Confirmed alert correlated correctly against attack traffic
- [x] Verified response body to determine if injection succeeded
- [ ] (Production scenario) Deploy a WAF in front of the application
- [ ] (Production scenario) Patch application to use parameterized
      queries/prepared statements instead of string-concatenated SQL
- [ ] (Production scenario) Rotate any credentials potentially exposed via
      the `users` table

## Recommendations

- This rule is signature-based and will miss encoded/obfuscated payloads
  (e.g. `UNION%0ASELECT`, mixed-case evasion, comment-split keywords like
  `UN/**/ION`). Recommend pairing with a WAF for normalization, or adding
  additional regex variants informed by real evasion techniques.
- Root-cause fix belongs in the application layer: DVWA is intentionally
  vulnerable for training purposes, but in a real app this alert should
  trigger a code review of the affected query, not just a SIEM response.
