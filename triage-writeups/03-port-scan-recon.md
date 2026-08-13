# Alert Triage Report — Port Scan / Network Recon

## Summary

| Field                | Value |
|-----------------------|-------|
| Alert / Rule ID        | 100030 |
| Rule Name              | Possible port scan / network recon detected from a single source |
| Date / Time (UTC)      | *2026-0X-XX 13:05:18* |
| Severity (Wazuh level) | 8 (Medium) |
| MITRE ATT&CK Technique | T1046 — Network Service Discovery |
| Source IP              | 192.168.56.30 (attacker/Kali) |
| Destination IP / Host  | 192.168.56.20 (Metasploitable2, all ports) |
| Analyst                | *your name* |
| Status                 | Closed — Confirmed (simulated) |

## Alert Details

```
rule.id: 100030
rule.description: Possible port scan / network recon detected from a single source
data.srcip: 192.168.56.30
count: 22 connection events in 20s window
ports observed: 21,22,23,25,53,80,111,139,445,512,513,514,1099,1524,2049,2121,3306,3632,5432,5900,6000,6667,8009,8180
```

## What happened (analysis)

An Nmap scan (`-sV -T4 --top-ports 100`, followed by a full `-sT -p-` TCP
connect scan) was run from the attacker VM against the victim host. This
generated a rapid burst of connection attempts across many ports in a short
window, crossing the rule's threshold of 15 events/20 seconds and firing
rule `100030`. The set of open ports discovered (FTP 21, SSH 22, Telnet 23,
SMTP 25, RPC 111, SMB 139/445, rlogin 512/513, NFS 2049, MySQL 3306,
PostgreSQL 5432, VNC 5900, IRC 6667) is characteristic of Metasploitable2's
intentionally exposed service set — classic reconnaissance ahead of
targeted exploitation.

## Evidence

- Screenshot: `../screenshots/portscan-alert.png`
- Nmap scan output saved alongside for reference

## Impact assessment

Reconnaissance only — no exploitation occurred in this alert by itself.
However, this scan directly informs what an attacker would target next
(e.g. the SQLi test against DVWA, or brute-forcing the exposed SSH service
seen in write-ups 01 and 02). In a real environment, this alert should be
treated as an early-warning signal and correlated against subsequent
alerts from the same source IP.

## False positive considerations

Legitimate vulnerability scanning tools (Nessus, OpenVAS) run by the
security team itself, or a monitoring/asset-discovery tool doing periodic
sweeps, would trigger an identical pattern. To rule out: maintain an
allowlist of known internal scanner IPs and exclude them from this rule, or
require scanning to occur during scheduled maintenance windows that are
cross-referenced against alert timestamps.

## Response actions taken

- [x] Confirmed alert fired correctly against scan traffic
- [x] Documented port/service fingerprint for correlation with later alerts
- [ ] (Production scenario) Flag source IP for enhanced monitoring
- [ ] (Production scenario) Cross-reference with threat intel feeds if IP
      is external

## Recommendations

- Correlate this rule with `100010` and `100020` in a dashboard view keyed
  on `source IP` — a single attacker triggering recon, then brute force,
  then SQLi within a short time window is a much stronger signal (attack
  chain) than any one alert alone, and is a good example of why SOC
  analysts pivot on IOC (source IP) across alert types rather than reading
  alerts in isolation.
- In production, reduce the exposed attack surface directly: this host
  legitimately should not have Telnet, rlogin, or NFS reachable — recon
  alerts are most valuable when they also surface unnecessary exposed
  services worth closing.
