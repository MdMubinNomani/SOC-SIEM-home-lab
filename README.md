# SOC / SIEM Home Lab

A self-contained Security Operations lab built to practice SIEM deployment, log
collection, detection engineering, and alert triage — the core day-to-day
workflow of a SOC analyst.

The lab deploys **Wazuh** (Elastic Stack under the hood: Elasticsearch/OpenSearch
indexer + Kibana-style dashboard) as the SIEM, feeds it logs from a
deliberately vulnerable host (Metasploitable2 / DVWA), simulates common
attacks against that host, and documents the resulting alerts as formal
triage write-ups — the same artifact a Tier-1 SOC analyst produces for every
incident.

---

## Why this project

This maps directly to real SOC / Security Monitoring responsibilities:

| SOC Responsibility        | Where it's demonstrated                          |
|----------------------------|---------------------------------------------------|
| SIEM deployment & tuning   | `setup/` — Wazuh install, agent config, log sources |
| Detection engineering      | `detection-rules/local_rules.xml`                 |
| Threat simulation          | `attack-simulations/`                              |
| Alert triage / IR docs     | `triage-writeups/`                                 |
| MITRE ATT&CK mapping       | Rules + triage docs tagged with technique IDs      |

---

## Architecture

```
┌─────────────────────┐        ┌───────────────────────────┐        ┌─────────────────────┐
│   Attacker (Kali)    │──────▶│   Vulnerable Host           │──────▶│   Wazuh Server        │
│  hydra / sqlmap /     │       │  Metasploitable2 / DVWA     │ logs  │  Manager + Indexer   │
│  nmap                 │       │  + Wazuh agent / rsyslog    │──────▶│  + Dashboard (UI)     │
└─────────────────────┘        └───────────────────────────┘        └───────────────────────────┘
                                                                              │
                                                                              ▼
                                                                    Alerts triggered by
                                                                    local_rules.xml,
                                                                    reviewed & triaged
                                                                    by analyst (you)
```

Three VMs on an isolated **host-only / NAT network** (no exposure to your real network):

1. **Wazuh server** — Ubuntu 22.04, 4GB+ RAM — manager, indexer, dashboard
2. **Victim** — Metasploitable2 or a DVWA box (Ubuntu + Apache/MySQL + DVWA)
3. **Attacker** — Kali or Parrot OS

---

## Workflow

1. **Deploy** the Wazuh server (single all-in-one install).
2. **Onboard** the victim host as a log source (Wazuh agent, or syslog
   forwarding for older systems like Metasploitable2).
3. **Write detections** in `local_rules.xml` for the attack classes we care
   about: SSH brute force, web SQL injection, port scan/recon.
4. **Simulate attacks** from the attacker VM using the scripts in
   `attack-simulations/`.
5. **Observe alerts** in the Wazuh dashboard, confirm the rules fired as
   expected, and screenshot the evidence.
6. **Triage** each alert using the template in `triage-writeups/`, producing
   one write-up per attack type — treating it exactly like a real SOC ticket.

---

## Repository structure

```
soc-siem-home-lab/
├── README.md                       # this file
├── setup/
│   ├── 01-wazuh-server-install.md  # install manager/indexer/dashboard
│   ├── 02-agent-onboarding.md      # Wazuh agent + syslog forwarding
│   └── 03-network-lab-topology.md  # VM networking setup
├── detection-rules/
│   ├── local_rules.xml             # custom Wazuh detection rules
│   └── rules-explained.md          # what each rule does & why
├── attack-simulations/
│   ├── ssh-bruteforce.sh           # hydra SSH brute force
│   ├── sqli-dvwa.sh                # sqlmap against DVWA
│   └── port-scan.sh                # nmap recon simulation
├── triage-writeups/
│   ├── TEMPLATE.md                 # blank triage report template
│   ├── 01-ssh-bruteforce.md        # completed example
│   ├── 02-sql-injection.md         # completed example
│   └── 03-port-scan-recon.md       # completed example
├── dashboards/
│   └── dashboard-notes.md          # panels/visualizations to build
└── screenshots/
    └── README.md                   # where to drop evidence screenshots
```

---

## Quick start

> Full step-by-step instructions are in `setup/`. Summary below.

### 1. Stand up the Wazuh server

```bash
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
sudo bash wazuh-install.sh -a
```

Save the admin credentials printed at the end. Dashboard is reachable at
`https://<wazuh-server-ip>/`.

### 2. Onboard the victim host

See `setup/02-agent-onboarding.md`. TL;DR — modern Linux victim (DVWA box):

```bash
curl -o wazuh-agent.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.0-1_amd64.deb
sudo WAZUH_MANAGER='<wazuh-server-ip>' dpkg -i ./wazuh-agent.deb
sudo systemctl enable --now wazuh-agent
```

For Metasploitable2 (too old for a native agent), forward syslog instead —
see `setup/02-agent-onboarding.md` for the rsyslog + manager-side config.

### 3. Load the custom detection rules

Copy `detection-rules/local_rules.xml` onto the **Wazuh manager** at
`/var/ossec/etc/rules/local_rules.xml`, validate, then restart:

```bash
sudo /var/ossec/bin/wazuh-logtest        # sanity check rule syntax
sudo systemctl restart wazuh-manager
```

### 4. Run the attack simulations

From the attacker VM:

```bash
./attack-simulations/ssh-bruteforce.sh <victim-ip>
./attack-simulations/sqli-dvwa.sh <victim-ip>
./attack-simulations/port-scan.sh <victim-ip>
```

### 5. Review alerts and triage

Open the Wazuh dashboard → **Security Events**, filter by rule ID
(`100010`, `100020`, `100030`), confirm the alert fired, screenshot it into
`screenshots/`, and fill out a copy of `triage-writeups/TEMPLATE.md` for
each incident.

---

## Detection rules included

| Rule ID | Name                          | Trigger                                   | MITRE ATT&CK        |
|---------|-------------------------------|--------------------------------------------|----------------------|
| 100010  | SSH Brute Force                | ≥6 failed SSH logins from one source in 120s | T1110 – Brute Force |
| 100020  | Possible SQL Injection         | SQLi patterns in web access logs           | T1190 – Exploit Public-Facing Application |
| 100030  | Port Scan / Recon              | ≥15 connection attempts from one source in 20s | T1046 – Network Service Discovery |

Full explanations in `detection-rules/rules-explained.md`.

---

## Tools used

- **Wazuh** (manager, indexer, dashboard) — SIEM / detection engine
- **Metasploitable2 / DVWA** — intentionally vulnerable target
- **Kali Linux** — attack simulation (Hydra, sqlmap, Nmap)
- **VirtualBox / VMware** — lab virtualization, isolated host-only network

## Disclaimer

This lab is built entirely on isolated, local virtual machines for
educational purposes. None of the tools or techniques here should be used
against systems you do not own or have explicit written permission to test.

## License

MIT — see `LICENSE`.
