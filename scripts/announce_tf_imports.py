#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path
import re

TF_DIR = Path("terraform")
OUTPUT_TF = TF_DIR / "proxmox_vms.tf"

print("[INFO] Generating Terraform configuration for existing Proxmox VMs...")

# Get Terraform outputs
vm_names_json = subprocess.check_output(["terraform", "-chdir=" + str(TF_DIR), "output", "-json", "vm_names"])
vm_ids_json = subprocess.check_output(["terraform", "-chdir=" + str(TF_DIR), "output", "-json", "vm_ids"])

vm_names = json.loads(vm_names_json)
vm_ids = json.loads(vm_ids_json)

if len(vm_names) != len(vm_ids):
    raise ValueError("vm_names and vm_ids length mismatch")

# Sanitize names for Terraform
sanitized_names = [re.sub(r"[^A-Za-z0-9_-]", "_", name) for name in vm_names]

# Write .tf file
with open(OUTPUT_TF, "w") as f:
    f.write("// Auto-generated Proxmox VM resources\n\n")
    for name in sanitized_names:
        f.write(f'resource "proxmox_vm_qemu" "{name}" {{\n')
        f.write("  count = 1\n")
        f.write(f'  name  = "{name}"\n')
        f.write("  # target_node = \"Dell-Optiplex\"\n")
        f.write("  # memory = 4096\n")
        f.write("  # cores = 2\n")
        f.write("}\n\n")

print(f"[INFO] Terraform configuration written to {OUTPUT_TF}")

# Print import commands
print("[INFO] You can now run these terraform import commands:")
seen_counts = {}
for name, vm_id in zip(sanitized_names, vm_ids):
    idx = seen_counts.get(name, 0)
    seen_counts[name] = idx + 1
    print(f'terraform import "proxmox_vm_qemu.{name}[{idx}]" "Dell-Optiplex/qemu/{vm_id}"')
