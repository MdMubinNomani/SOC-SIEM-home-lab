# Wazuh Dashboard — Panels to Build

Suggested visualizations to add to a custom dashboard in Wazuh (Kibana/
OpenSearch Dashboards under the hood), useful both for day-to-day triage and
as portfolio screenshots.

## 1. Alerts by MITRE ATT&CK Technique
- Visualization type: bar chart / data table
- Field: `rule.mitre.id`
- Shows attack-technique coverage at a glance (T1110, T1190, T1046).

## 2. Top Source IPs by Alert Count
- Visualization type: data table / pie chart
- Field: `data.srcip` or `agent.ip`
- Quickly surfaces which host is generating the most alerts — your attacker
  VM should dominate this in the lab.

## 3. Alert Severity Over Time
- Visualization type: stacked area / histogram
- Fields: `timestamp` (x-axis), `rule.level` (stacking/color)
- Useful to visually correlate the recon → brute force → SQLi attack chain
  timeline from the triage write-ups.

## 4. Rule Firing Frequency
- Visualization type: bar chart
- Field: `rule.id` / `rule.description`
- Confirms each custom rule (100010, 100011, 100020, 100030) is actually
  firing as expected — good sanity-check panel while building rules.

## 5. Attack Chain Timeline (single source IP)
- Filter: `data.srcip: 192.168.56.30`
- Sort: timestamp ascending
- This is the money shot for a portfolio screenshot — shows a single
  attacker moving from recon → brute force → exploitation, all captured and
  correlated by the SIEM.

---

## How to build a panel (general steps)

1. Wazuh dashboard → **Dashboard Management → Visualizations → Create**
2. Choose visualization type, select the `wazuh-alerts-*` index pattern
3. Pick the field(s) above as bucket/metric
4. Save, then add to a new or existing **Dashboard**
5. Screenshot for `../screenshots/`
