#!/usr/bin/env bash
set -euo pipefail

TF_DIR="terraform"
OUTPUT_TF="$TF_DIR/proxmox_vms.tf"

echo "[INFO] Generating Terraform configuration for existing Proxmox VMs..."

# Read Terraform outputs
VM_NAMES=$(terraform -chdir="$TF_DIR" output -json vm_names)
VM_IDS=$(terraform -chdir="$TF_DIR" output -json vm_ids)

# Flatten JSON arrays
NAMES=($(echo "$VM_NAMES" | jq -r '.[]'))
IDS=($(echo "$VM_IDS" | jq -r '.[]'))

if [ "${#NAMES[@]}" -ne "${#IDS[@]}" ]; then
    echo "[ERROR] vm_names and vm_ids length mismatch"
    exit 1
fi

# Track how many times each name occurs for indexing
declare -A NAME_INDEX

# Write .tf file
echo "// Auto-generated Proxmox VM resources" > "$OUTPUT_TF"

for i in "${!NAMES[@]}"; do
    NAME="${NAMES[$i]}"
    ID="${IDS[$i]}"
    IDX=${NAME_INDEX["$NAME"]:0}

    # Write Terraform resource
    cat >> "$OUTPUT_TF" <<EOF
resource "proxmox_vm_qemu" "${NAME}" {
  count = 1
  name  = "${NAME}"
  # target_node = "proxmox-node1"
  # memory = 4096
  # cores = 2
}
EOF

    NAME_INDEX["$NAME"]=$((IDX+1))
done

echo "[INFO] Terraform configuration written to $OUTPUT_TF"

# Print import commands using indexed syntax
echo "[INFO] You can now run these terraform import commands:"
unset NAME_INDEX
declare -A NAME_INDEX
for i in "${!NAMES[@]}"; do
    NAME="${NAMES[$i]}"
    ID="${IDS[$i]}"
    IDX=${NAME_INDEX["$NAME"]:0}
    echo "terraform import \"proxmox_vm_qemu.${NAME}[${IDX}]\" \"${ID}\""
    NAME_INDEX["$NAME"]=$((IDX+1))
done
