#!/usr/bin/env bash

set -euo pipefail

VICTIM_IP="${1:?Usage: $0 <victim-ip>}"

echo "[*] Target : $VICTIM_IP"
echo "[*] This will trigger Wazuh rule 100030 (Port Scan / Recon)."
echo

echo "[1/2] Fast SYN scan across common ports"
nmap -sV -T4 --top-ports 100 "$VICTIM_IP"

echo
echo "[2/2] Full TCP connect scan (noisier, generates more log entries —"
echo "      useful if the fast scan alone didn't cross the rule's threshold)"
nmap -sT -T4 -p- "$VICTIM_IP"

echo
echo "[*] Done. Check the Wazuh dashboard -> Security Events, filter rule.id:100030"
