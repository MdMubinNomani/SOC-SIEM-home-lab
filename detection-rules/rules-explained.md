# Detection Rules — Explained

This document walks through the logic and reasoning behind each custom rule
in `local_rules.xml`, so the "why," not just the "what," is documented —
which is exactly what a detection engineer is expected to justify.

---

## 100010 — SSH Brute Force (T1110)

```xml
<rule id="100010" level="10" frequency="6" timeframe="120">
  <if_matched_sid>5716</if_matched_sid>
  <same_source_ip />
  ...
```

- **Base rule**: builds on Wazuh's existing `5716` (SSHD authentication
  failure), rather than re-parsing raw syslog — avoids duplicating decoder
  logic Wazuh already maintains.
- **Logic**: correlates 6+ failures from the *same source IP* inside a
  120-second window. A single failed login is normal user error; 6 in 2
  minutes is not.
- **Tuning consideration**: 6/120s is deliberately loose for a lab. In
  production you'd tune frequency/timeframe against real baseline traffic to
  avoid alerting on e.g. a misconfigured cron job retrying a stale key.
- **Severity**: level 10 (high) — brute force is an active, intentional
  attack technique, not background noise.

## 100011 — Brute Force → Successful Login (T1110 / T1078)

- **Logic**: if rule `100010` fires and is followed by a *successful* login
  (`5715`) from the same source, that's the difference between "someone is
  trying" and "someone may have gotten in."
- **Severity**: level 14 — this is the alert that should page someone at
  3am. It's a strong indicator of account compromise, not just attack
  attempts.
- **Why it matters for triage**: distinguishing "attempted" vs "likely
  succeeded" is the single most important judgment call in brute-force
  incident response — it changes the response from "block IP" to "assume
  breach, rotate credentials, check for lateral movement."

## 100020 — Possible SQL Injection (T1190)

- **Base rule**: `31100`, Wazuh's generic web-attack parent rule for parsed
  Apache/Nginx access logs.
- **Logic**: regex against the requested URL for classic SQLi tokens —
  `UNION SELECT`, tautologies (`OR 1=1`), comment terminators (`--`),
  `information_schema` enumeration, time-based blind indicators (`SLEEP(`).
- **Known limitation**: signature/regex-based detection will miss encoded
  or obfuscated payloads (e.g. URL-encoded, case-mixed, or comment-split
  keywords). Worth noting in the write-up as a real limitation of
  signature-based SIEM rules vs. a WAF with normalization.
- **Severity**: level 12 — SQLi is a direct attempt at data
  exfiltration/integrity compromise, warrants high severity even as a lone
  attempt.

## 100030 — Port Scan / Recon (T1046)

- **Logic**: 15+ discrete connection events from one source within 20
  seconds — modeled on Nmap's default timing (`-T3`/`-T4`) generating rapid
  sequential connection attempts across ports.
- **Caveat documented deliberately**: the `if_sid` here needs to point at
  whatever your actual connection/firewall log source emits (e.g. iptables
  LOG rule, or Metasploitable2's own connection logs via syslog) — this is
  the one rule you should expect to adjust to match your specific log
  format, and that adjustment process is itself worth writing up as part of
  the "detection engineering" narrative for this project.
- **Severity**: level 8 (medium) — reconnaissance alone isn't compromise,
  but it's the reliable precursor worth flagging and correlating against
  later alerts from the same source IP.

---

## General notes on rule design choices

- **`same_source_ip`** is used throughout to correlate by attacker, not by
  target — this is what turns "one failed login" noise into "one attacker,
  many failures" signal.
- **MITRE ATT&CK tagging** on every rule isn't cosmetic — it's what lets you
  later build a dashboard panel like "alerts by ATT&CK technique," which is
  a very SOC-manager-friendly view and a good screenshot for the portfolio.
- **Severity levels** follow Wazuh's convention (0–15, 12+ generally
  considered high/critical) so alerts sort meaningfully in the dashboard
  without extra configuration.
