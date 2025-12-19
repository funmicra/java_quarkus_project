#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Variables
# -----------------------------
WORKSPACE="${WORKSPACE:-$(pwd)}"
KUBESPRAY_DIR="$WORKSPACE/kubespray"
HOSTS_INI="$WORKSPACE/ansible/hosts.ini"
CONFIG_FILE="$KUBESPRAY_DIR/inventory/mycluster/hosts.yaml"

# -----------------------------
# Clone Kubespray
# -----------------------------
rm -rf "$KUBESPRAY_DIR"
git clone https://github.com/kubernetes-sigs/kubespray.git "$KUBESPRAY_DIR"
cd "$KUBESPRAY_DIR"

# -----------------------------
# Setup Python venv
# -----------------------------
python3 -m venv venv
. venv/bin/activate
python3 -m pip install --upgrade pip
pip install -r requirements.txt

# -----------------------------
# Prepare inventory
# -----------------------------
cp -rfp inventory/sample inventory/mycluster

if [ ! -f "$HOSTS_INI" ]; then
    echo "[ERROR] Hosts file not found: $HOSTS_INI"
    exit 1
fi

# Extract hosts
CTRL_PLANE_HOSTS=$(awk -F'ansible_host=' '/ctrl-plane/ {print $1 ":" $2}' "$HOSTS_INI" | tr -d ' ')
WORKER_HOSTS=$(awk -F'ansible_host=' '/worker/ {print $1 ":" $2}' "$HOSTS_INI" | tr -d ' ')

# Generate hosts.yaml
echo "all:" > "$CONFIG_FILE"
echo "  hosts:" >> "$CONFIG_FILE"

for host in $CTRL_PLANE_HOSTS $WORKER_HOSTS; do
    NAME=$(echo $host | cut -d: -f1)
    IP=$(echo $host | cut -d: -f2)
    echo "    $NAME:" >> "$CONFIG_FILE"
    echo "      ansible_host: $IP" >> "$CONFIG_FILE"
    echo "      ip: $IP" >> "$CONFIG_FILE"
    echo "      access_ip: $IP" >> "$CONFIG_FILE"
done

# Build children groups
echo "  children:" >> "$CONFIG_FILE"

echo "    kube_control_plane:" >> "$CONFIG_FILE"
echo "      hosts:" >> "$CONFIG_FILE"
for host in $CTRL_PLANE_HOSTS; do
    NAME=$(echo $host | cut -d: -f1)
    echo "        $NAME:" >> "$CONFIG_FILE"
done

echo "    kube_node:" >> "$CONFIG_FILE"
echo "      hosts:" >> "$CONFIG_FILE"
for host in $WORKER_HOSTS; do
    NAME=$(echo $host | cut -d: -f1)
    echo "        $NAME:" >> "$CONFIG_FILE"
done

echo "    etcd:" >> "$CONFIG_FILE"
echo "      hosts:" >> "$CONFIG_FILE"
for host in $CTRL_PLANE_HOSTS; do
    NAME=$(echo $host | cut -d: -f1)
    echo "        $NAME:" >> "$CONFIG_FILE"
done

echo "    k8s_cluster:" >> "$CONFIG_FILE"
echo "      children:" >> "$CONFIG_FILE"
echo "        kube_control_plane:" >> "$CONFIG_FILE"
echo "        kube_node:" >> "$CONFIG_FILE"

echo "    calico_rr:" >> "$CONFIG_FILE"
echo "      hosts: {}" >> "$CONFIG_FILE"

# -----------------------------
# Run Kubespray playbook
# -----------------------------
ansible-playbook -i "$CONFIG_FILE" \
    --private-key ~/.ssh/id_rsa \
    -u funmicra \
    --become --become-user=root \
    cluster.yml
