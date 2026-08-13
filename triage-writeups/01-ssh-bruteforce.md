# Alert Triage Report — SSH Brute Force

## Summary

| Field                | Value |
|-----------------------|-------|
| Alert / Rule ID        | 100010 |
| Rule Name              | SSH brute force attempt: multiple failed logins from the same source |
| Date / Time (UTC)      | *2026-0X-XX 14:32:07* |
| Severity (Wazuh level) | 10 (High) |
| MITRE ATT&CK Technique | T1110 — Brute Force |
| Source IP              | 192.168.56.30 (attacker/Kali) |
| Destination IP / Host  | 192.168.56.20:22 (Metasploitable2) |
| Analyst                | *your name* |
| Status                 | Closed — Confirmed (simulated) |

## Alert Details

```
rule.id: 100010
rule.description: SSH brute force attempt: multiple failed logins from the same source
data.srcip: 192.168.56.30
agent.name: metasploitable2
full_log: sshd[1421]: Failed password for msfadmin from 192.168.56.30 port 51422 ssh2
(x8 within 120s window)
```

## What happened (analysis)

Hydra was used from the attacker VM to run a dictionary attack against the
SSH service on the victim host, targeting the `msfadmin` account with
`rockyou.txt`. Eight failed authentication attempts occurred from the same
source IP within roughly 40 seconds — well over the rule's 6-attempts/120s
threshold. Wazuh's base rule `5716` (SSHD auth failure) fired repeatedly and
was correlated by `same_source_ip`, escalating to custom rule `100010`.

No corresponding successful login (rule `5715`) was observed in this run, so
the escalation rule `100011` did not fire — this attack was **attempted but
not successful**.

## Evidence

- Screenshot: `../screenshots/ssh-bruteforce-alert.png`
- Related alerts: 8x rule `5716` (base failed-login events) preceding the
  `100010` correlation alert

## Impact assessment

Attempted only — no evidence of successful authentication. If the target
account's password had been present in the wordlist, this would have
escalated to rule `100011` (possible compromise) and warranted immediate
credential rotation and a check for post-auth activity (new SSH sessions,
cron changes, added authorized_keys).

## False positive considerations

A legitimate user repeatedly mistyping their password, or an automated
script/monitoring tool with a stale credential retrying on a schedule, could
also trigger this rule. To rule out: check whether the source IP is a known
internal service account vs. an unrecognized/external address, and whether
failures stop after a short burst (human error) vs. continue steadily
(automated attack) — this run showed a fast, tight cadence tell-tale of
tooling.

## Response actions taken

- [x] Confirmed alert correlated correctly against attack traffic
- [x] Verified no successful login followed (checked for rule 5715 / 100011)
- [ ] (Production scenario) Block source IP at perimeter firewall
- [ ] (Production scenario) Enforce SSH key-based auth / disable password auth
- [ ] (Production scenario) Add fail2ban or equivalent for automated IP banning

## Recommendations

- Disable SSH password authentication in favor of key-based auth on
  internet-facing hosts — this closes the brute-force vector entirely
  rather than just detecting it.
- Consider lowering the rule's frequency threshold (e.g. 4 attempts/120s) if
  production baseline traffic supports it, for faster detection.
- Add an automated response (Wazuh active response) to firewall-block the
  source IP when rule `100010` fires, rather than relying on manual triage.
