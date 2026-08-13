# 02 — Onboarding the Victim Host

You have two paths depending on which victim you chose.

---

## Option A — DVWA box (modern Ubuntu) → native Wazuh agent

Recommended if you want clean web log ingestion for the SQLi rule.

1. Install DVWA on an Ubuntu 22.04 VM (Apache + PHP + MySQL), or use a
   ready-made DVWA appliance/Docker image.
2. Install the Wazuh agent:

```bash
curl -o wazuh-agent.deb https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.9.0-1_amd64.deb
sudo WAZUH_MANAGER='<wazuh-server-ip>' dpkg -i ./wazuh-agent.deb
sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent
```

3. Confirm enrollment on the **manager**:

```bash
sudo /var/ossec/bin/manage_agents -l
```

The DVWA host should appear as `Active`.

4. Add Apache log monitoring so SQLi attempts are visible to the rule
   engine. Edit `/var/ossec/etc/ossec.conf` **on the agent**:

```xml
<ossec_config>
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/apache2/access.log</location>
  </localfile>
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/apache2/error.log</location>
  </localfile>
</ossec_config>
```

Restart the agent: `sudo systemctl restart wazuh-agent`

---

## Option B — Metasploitable2 → syslog forwarding

Metasploitable2 (Ubuntu 8.04-based) is too old for the modern Wazuh agent, so
forward its logs via syslog instead.

**On Metasploitable2**, edit `/etc/rsyslog.conf` and add at the bottom:

```
*.* @<wazuh-server-ip>:514
```

Restart syslog:

```bash
sudo /etc/init.d/rsyslog restart
```

**On the Wazuh manager**, add a remote syslog listener in
`/var/ossec/etc/ossec.conf`:

```xml
<ossec_config>
  <remote>
    <connection>syslog</connection>
    <port>514</port>
    <protocol>udp</protocol>
    <allowed-ips><VICTIM-IP>/32</allowed-ips>
  </remote>
</ossec_config>
```

Restart the manager:

```bash
sudo systemctl restart wazuh-manager
```

Generate a failed SSH login on Metasploitable2 and confirm the event lands
in the Wazuh dashboard under **Security Events** before moving on.

---

## Sanity check (either option)

From the Wazuh dashboard: **Agents** (Option A) or **Security Events →
filter by source IP** (Option B) — you should see live events within a
minute of generating traffic (e.g. `ssh <victim-ip>` with a wrong password).

Next: `03-network-lab-topology.md`
