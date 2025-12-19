#!/usr/bin/sh
set -euo pipefail

TF_DIR="terraform"
OUTPUT_TF="$TF_DIR/proxmox_vms.tf"

echo "[INFO] Generating Terraform configuration for existing Proxmox VMs..."

# Read Terraform outputs
VM_NAMES=$(terraform -chdir="$TF_DIR" output -json vm_names)
VM_IDS=$(terraform -chdir="$TF_DIR" output -json vm_ids)

# Flatten JSON arrays and sanitize names
NAMES=($(echo "$VM_NAMES" | jq -r '.[]' | sed 's/[^A-Za-z0-9_]/_/g'))
IDS=($(echo "$VM_IDS" | jq -r '.[]'))

if [ "${#NAMES[@]}" -ne "${#IDS[@]}" ]; then
    echo "[ERROR] vm_names and vm_ids length mismatch"
    exit 1
fi

# Write .tf file
echo "// Auto-generated Proxmox VM resources" > "$OUTPUT_TF"

for i in "${!NAMES[@]}"; do
    NAME="${NAMES[$i]}"
    ID="${IDS[$i]}"

    cat >> "$OUTPUT_TF" <<EOF
resource "proxmox_vm_qemu" "${NAME}" {
  # VM will be imported manually
  # Replace the following with your VM settings if desired
  name = "${NAME}"
  # target_node = "proxmox-node1"
  # memory = 4096
  # cores = 2
}
EOF

done

echo "[INFO] Terraform configuration written to $OUTPUT_TF"

echo "[INFO] You can now run:"
for NAME in "${NAMES[@]}"; do
    IDX=$(echo "${!NAMES[@]}" | tr ' ' '\n' | grep -n "^$NAME\$" | cut -d: -f1)
    echo "terraform import proxmox_vm_qemu.${NAME} ${IDS[$((IDX-1))]}"
done
