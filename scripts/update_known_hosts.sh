#!/usr/bin/env bash
set -euo pipefail

INVENTORY="${1:-ansible/hosts.ini}"
KNOWN_HOSTS="${2:-/var/lib/jenkins/.ssh/known_hosts}"

if [ ! -f "$INVENTORY" ]; then
    echo "[ERROR] Inventory not found: $INVENTORY"
    exit 1
fi

echo "[INFO] Updating known_hosts from inventory: $INVENTORY"

# Extract hostnames/IPs:
# - ignore group headers ([...])
# - ignore blank lines
# - ignore variable definitions (lines with =)
awk '
/^[[]/ { next }
/^[[:space:]]*$/ { next }
/=/ { next }
{ print $1 }
' "$INVENTORY" | while read -r host; do
    echo "[INFO] Scanning $host"
    ssh-keyscan -H "$host" >> "$KNOWN_HOSTS" 2>/dev/null || true
done

# Ensure Jenkins owns the file
chown -R jenkins:jenkins "$(dirname "$KNOWN_HOSTS")"

echo "[INFO] known_hosts updated successfully"
