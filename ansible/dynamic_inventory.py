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
TF_DIR = (SCRIPT_DIR / "../terraform").resolve()
OUTPUT_FILE = SCRIPT_DIR / "hosts.ini"

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

def tf_output(name):
    """
    Always consume Terraform output as JSON.
    Treat Terraform like an API, not a CLI.
    """
    cmd = [
        "terraform",
        f"-chdir={TF_DIR}",
        "output",
        "-json",
        name,
    ]

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

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        print(f"[ERROR] terraform output '{name}' is not valid JSON", file=sys.stderr)
        print(result.stdout, file=sys.stderr)
        sys.exit(1)

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

def main():
    if not TF_DIR.exists():
        print(f"[ERROR] Terraform directory not found: {TF_DIR}", file=sys.stderr)
        sys.exit(1)

    vm_names = tf_output("vm_names")
    vm_ids   = tf_output("vm_ids")
    vm_ips   = tf_output("vm_ips")

    # Type and sanity checks
    for key, value in {
        "vm_names": vm_names,
        "vm_ids": vm_ids,
        "vm_ips": vm_ips,
    }.items():
        if not isinstance(value, list) or not value:
            print(f"[ERROR] Terraform output '{key}' is empty or not a list", file=sys.stderr)
            sys.exit(1)

    if not (len(vm_names) == len(vm_ids) == len(vm_ips)):
        print(
            "[ERROR] Terraform outputs length mismatch: "
            f"names={len(vm_names)}, ids={len(vm_ids)}, ips={len(vm_ips)}",
            file=sys.stderr,
        )
        sys.exit(1)

    inventory = [
        "[rocky_nodes]",
    ]

    for name, vmid, ip in zip(vm_names, vm_ids, vm_ips):
        inventory.append(
            f"{name} ansible_host={ip}"
        )

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

# ------------------------------------------------------------------

if __name__ == "__main__":
    main()
