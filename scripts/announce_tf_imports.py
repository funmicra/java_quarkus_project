#!/usr/bin/env python3
import json
from pathlib import Path

# Path to your Terraform outputs file
TF_OUTPUTS_FILE = Path("terrafrm/terraform_outputs.json")

if not TF_OUTPUTS_FILE.exists():
    print(f"[ERROR] {TF_OUTPUTS_FILE} not found!")
    exit(1)

# Load JSON
with open(TF_OUTPUTS_FILE) as f:
    tf_outputs = json.load(f)

vm_names = tf_outputs["vm_names"]["value"]
vm_ids   = tf_outputs["vm_ids"]["value"]

# Map VM names to Terraform resource names
# For example, multiple workers -> "workers" array
resource_map = {
    "ctrl-plane": "ctrl-plane",
    "worker-1": "workers",
    "worker-2": "workers"  # add more if needed
}

# Track indexes for array-style Terraform resources
seen_counts = {}

print("[INFO] You can now run these Terraform import commands:")
for name, vm_id in zip(vm_names, vm_ids):
    tf_name = resource_map.get(name, name.replace("-", "_"))
    idx = seen_counts.get(tf_name, 0)
    seen_counts[tf_name] = idx + 1

    # Construct Proxmox import ID format
    import_id = f"Dell-Optiplex/qemu/{vm_id}"
    print(f'terraform import "proxmox_vm_qemu.{tf_name}[{idx}]" "{import_id}"')
