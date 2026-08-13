# 01 — Wazuh Server Install

## Requirements

- Ubuntu 22.04 LTS VM
- 4 vCPU / 4GB+ RAM / 50GB disk (indexer is the heavy part)
- Static IP on the lab's host-only/NAT network
- Outbound internet access during install (to pull packages)

## Install (all-in-one)

Wazuh ships a single script that installs the indexer (OpenSearch-based),
manager, and dashboard together — good enough for a lab-scale deployment.

```bash
curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh
sudo bash wazuh-install.sh -a
```

This takes 5–15 minutes. At the end it prints the auto-generated `admin`
password for the dashboard — **copy it somewhere safe**, it's not shown again
(you can regenerate it later with `wazuh-passwords-tool.sh` if needed).

## Verify services

```bash
sudo systemctl status wazuh-manager
sudo systemctl status wazuh-indexer
sudo systemctl status wazuh-dashboard
```

All three should report `active (running)`.

## Access the dashboard

Browse to `https://<wazuh-server-ip>/` (self-signed cert — accept the browser
warning) and log in with `admin` + the password from the install output.

## Firewall notes

If you're running `ufw`, make sure these are open on the manager:

| Port      | Purpose                          |
|-----------|-----------------------------------|
| 1514/tcp  | Agent event data                  |
| 1515/tcp  | Agent enrollment                  |
| 514/udp   | Syslog (for Metasploitable2)      |
| 443/tcp   | Dashboard web UI                  |

```bash
sudo ufw allow 1514/tcp
sudo ufw allow 1515/tcp
sudo ufw allow 514/udp
sudo ufw allow 443/tcp
```

Next: `02-agent-onboarding.md`
