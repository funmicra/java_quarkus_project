#!/usr/bin/env python3
import json
import subprocess
import re
from pathlib import Path

TF_DIR = Path("terraform")

print("[INFO] Generating Terraform import commands for existing Proxmox VMs...")

# Get Terraform outputs
try:
    vm_names_json = subprocess.check_output(
        ["terraform", "-chdir=" + str(TF_DIR), "output", "-json", "vm_names"],
        text=True
    )
    vm_ids_json = subprocess.check_output(
        ["terraform", "-chdir=" + str(TF_DIR), "output", "-json", "vm_ids"],
        text=True
    )
except subprocess.CalledProcessError:
    print("[ERROR] Terraform outputs 'vm_names' or 'vm_ids' do not exist yet. Run terraform apply first.")
    exit(1)

vm_names = json.loads(vm_names_json)
vm_ids = json.loads(vm_ids_json)

# Map Terraform-friendly names (example: 'worker-1' -> 'workers')
# You can customize this mapping if needed
name_map = {
    "ctrl-plane": "ctrl-plane",
    "worker-1": "workers",
    "worker-2": "workers"
}

# Track counts for index notation
seen_counts = {}

print("[INFO] You can now run these terraform import commands:")
for name, vm_id in zip(vm_names, vm_ids):
    tf_name = name_map.get(name, re.sub(r"[^A-Za-z0-9_]", "_", name))
    idx = seen_counts.get(tf_name, 0)
    seen_counts[tf_name] = idx + 1
    print(f'terraform import "proxmox_vm_qemu.{tf_name}[{idx}]" "{vm_id}"')
