import json
from pathlib import Path
import sys

ANSIBLE_USER = "funmicra"
SCRIPT_DIR = Path(__file__).resolve().parent
TF_OUTPUT_FILE = (SCRIPT_DIR / "../terraform/terraform_outputs.json").resolve()
OUTPUT_FILE = SCRIPT_DIR / "hosts.ini"

# Load Terraform outputs from JSON
if not TF_OUTPUT_FILE.exists():
    print(f"[ERROR] Terraform outputs file not found: {TF_OUTPUT_FILE}", file=sys.stderr)
    sys.exit(1)

with open(TF_OUTPUT_FILE) as f:
    data = json.load(f)

try:
    vm_names = data["vm_names"]["value"]
    vm_ids   = data["vm_ids"]["value"]
    vm_ips   = data["vm_ips"]["value"]
except KeyError as e:
    print(f"[ERROR] Terraform output missing key: {e}", file=sys.stderr)
    sys.exit(1)

# Sanity checks
if not (len(vm_names) == len(vm_ids) == len(vm_ips)):
    print("[ERROR] Length mismatch between VM outputs", file=sys.stderr)
    sys.exit(1)

# Generate inventory
inventory = ["[rocky_nodes]"]
for name, ip in zip(vm_names, vm_ips):
    inventory.append(f"{name} ansible_host={ip}")

inventory.extend([
    "",
    "[rocky_nodes:vars]",
    f"ansible_user={ANSIBLE_USER}",
    "ansible_become=true",
    "ansible_python_interpreter=/usr/bin/python3",
    "",
])

OUTPUT_FILE.write_text("\n".join(inventory))
print(f"[OK] Static inventory written to {OUTPUT_FILE}")
