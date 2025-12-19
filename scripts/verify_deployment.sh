#!/usr/bin/env bash
set -euo pipefail

INVENTORY="${1:-ansible/hosts.ini}"
URL_PATH="${2:-/sample?param=java}"
PORT="${3:-30080}"
MAX_RETRIES="${4:-5}"
SLEEP_BETWEEN="${5:-5}"

if [ ! -f "$INVENTORY" ]; then
    echo "[ERROR] Inventory not found: $INVENTORY"
    exit 1
fi

# Extract ansible_host IPs
HOSTS=$(awk '
/^[[]/ { next }
/^[[:space:]]*$/ { next }
/=/ { 
    if ($0 ~ /ansible_host=/) {
        split($0, a, "="); print a[2]
    }
}
' "$INVENTORY")

if [ -z "$HOSTS" ]; then
    echo "[ERROR] No hosts found in $INVENTORY"
    exit 1
fi

echo "[INFO] Verifying deployment on hosts: $HOSTS"

for host in $HOSTS; do
    attempt=0
    until [ $attempt -ge $MAX_RETRIES ]; do
        echo "[INFO] Testing http://$host:$PORT$URL_PATH (attempt $((attempt+1))/$MAX_RETRIES)..."
        if curl -s -f "http://$host:$PORT$URL_PATH"; then
            echo "[OK] $host responded successfully."
            break
        else
            echo "[WARN] $host did not respond. Retrying in $SLEEP_BETWEEN seconds..."
            attempt=$((attempt+1))
            sleep $SLEEP_BETWEEN
        fi
    done

    if [ $attempt -eq $MAX_RETRIES ]; then
        echo "[ERROR] $host failed after $MAX_RETRIES attempts."
        exit 1
    fi
done

echo "[INFO] All hosts responded successfully."
