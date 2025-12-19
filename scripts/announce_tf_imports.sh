#!/usr/bin/env bash
set -euo pipefail

TF_DIR="${1:-terraform}"
OUTPUT_FILE="$TF_DIR/terraform_outputs.json"

if [ ! -d "$TF_DIR" ]; then
    echo "[ERROR] Terraform directory not found: $TF_DIR"
    exit 1
fi

# Read outputs from JSON (require jq)
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "[INFO] terraform_outputs.json not found — generating from Terraform..."
    terraform -chdir="$TF_DIR" output -json > "$OUTPUT_FILE"
fi

echo "[INFO] Announcing Terraform import commands..."

VM_IDS=$(jq -r '.vm_ids[]' "$OUTPUT_FILE")
VM_NAMES=$(jq -r '.vm_names[]' "$OUTPUT_FILE")

# Combine names and IDs
paste <(echo "$VM_NAMES") <(echo "$VM_IDS") | while read -r name id; do
    echo "terraform import proxmox_vm_qemu.$name $id"
done

echo "[OK] Done generating Terraform import commands."
