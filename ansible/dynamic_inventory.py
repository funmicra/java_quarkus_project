#!/usr/bin/env python3
import json
import subprocess
import sys
from pathlib import Path

# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------

ANSIBLE_USER = "funmicra"

SCRIPT_DIR = Path(__file__).resolve().parent
TF_DIR = (SCRIPT_DIR / "../../terraform").resolve()
OUTPUT_FILE = SCRIPT_DIR / "hosts.ini"

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

def tf_output(name, json_output=False):
    cmd = ["terraform", f"-chdir={TF_DIR}", "output"]
    if json_output:
        cmd.append("-json")
    cmd.append(name)

    try:
        result = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] terraform output '{name}' failed", file=sys.stderr)
        print(e.stderr, file=sys.stderr)
        sys.exit(1)

    out = result.stdout.strip()
    return json.loads(out) if json_output else out

def normalize_ip(value):
    """
    Ensure the IP is a clean string with no quotes or whitespace.
    """
    if not value:
        return ""
    return str(value).strip().strip('"').strip("'")

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

def main():
    if not TF_DIR.exists():
        print(f"[ERROR] Terraform directory not found: {TF_DIR}", file=sys.stderr)
        sys.exit(1)

    vm_names = tf_output("vm_names")
    vm_ids = tf_output("vm_ids")

    if not vm_names or not vm_ids:
        print("[ERROR] vm_names or vm_ids output is empty", file=sys.stderr)
        sys.exit(1)

    if len(vm_names) != len(vm_ids):
        print("[ERROR] vm_names and vm_ids length mismatch", file=sys.stderr)
        sys.exit(1)

    inventory = [
        "[proxmox]",
    ]

    for name, vmid in zip(vm_names, vm_ids):
        inventory.append(f"{name} vmid={vmid}")

    inventory.extend([
        "",
        "[proxmox:vars]",
        f"ansible_user={ANSIBLE_USER}",
        "",
    ])

    OUTPUT_FILE.write_text("\n".join(inventory))
    print(f"[OK] Static inventory written to {OUTPUT_FILE}")

# ------------------------------------------------------------------

if __name__ == "__main__":
    main()
