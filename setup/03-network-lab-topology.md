# 03 — Lab Network Topology

## Goal

Keep every attack fully contained. Nothing here should ever touch your real
LAN or the internet except for package downloads during install.

## Recommended setup (VirtualBox)

1. Create a **Host-Only Network** (`File → Host Network Manager`), e.g.
   `192.168.56.0/24`, DHCP disabled — assign static IPs manually.
2. Attach all three VMs to this host-only adapter as their **only** network
   interface (or as a second adapter if you need adapter 1 = NAT purely for
   package installs, then disable/detach it after setup).

| VM              | Suggested static IP   |
|------------------|------------------------|
| Wazuh server     | 192.168.56.10          |
| Victim (DVWA/Metasploitable2) | 192.168.56.20 |
| Attacker (Kali)  | 192.168.56.30          |

## VMware equivalent

Use a **Host-Only** or **Custom (VMnet)** network in the Virtual Network
Editor instead of Bridged/NAT, same IP scheme.

## Verify isolation

From the attacker VM:

```bash
ping -c 2 192.168.56.10   # should work — Wazuh server
ping -c 2 8.8.8.8         # should fail/timeout if isolated correctly
```

## Static IP example (Ubuntu victim/server, netplan)

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses: [192.168.56.10/24]
```

```bash
sudo netplan apply
```

Once all three VMs can reach each other on `192.168.56.0/24` and cannot
reach anything else, you're ready for `detection-rules/` and
`attack-simulations/`.
