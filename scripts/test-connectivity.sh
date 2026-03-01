#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib.sh"

require_cmd ssh
require_cmd ping

load_scalar_vars

# Read all node data into arrays first (Bash 3.2 compatible)
vm_names=()
vm_ips=()
vm_macs=()
nodes_output=$(node_rows)
while IFS='|' read -r vm_name vm_ip vm_mac; do
  vm_names+=("$vm_name")
  vm_ips+=("$vm_ip")
  vm_macs+=("$vm_mac")
done <<< "$nodes_output"

# Test SSH connectivity to all nodes first
echo "Testing SSH connectivity to all nodes..."
ssh_ok=true
for i in "${!vm_names[@]}"; do
  vm_name=${vm_names[$i]}
  vm_ip=${vm_ips[$i]}
  
  if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "${CLOUD_USER}@${vm_ip}" 'echo OK' >/dev/null 2>&1; then
    echo "✗ SSH to $vm_name ($vm_ip) failed" >&2
    ssh_ok=false
  else
    echo "✓ SSH to $vm_name ($vm_ip) OK"
  fi
done

if [ "$ssh_ok" = false ]; then
  echo "SSH connectivity failed. Aborting network tests." >&2
  exit 1
fi

echo ""
echo "Testing network connectivity (ping) between all nodes..."

connectivity_ok=true

# Test connectivity from each node to all other nodes
for i in "${!vm_names[@]}"; do
  source_name=${vm_names[$i]}
  source_ip=${vm_ips[$i]}
  
  for j in "${!vm_names[@]}"; do
    dest_name=${vm_names[$j]}
    dest_ip=${vm_ips[$j]}
    
    # Skip testing to self
    if [ "$source_ip" = "$dest_ip" ]; then
      continue
    fi
    
    # Test connectivity
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "${CLOUD_USER}@${source_ip}" "ping -c 1 -W 1 ${dest_ip} >/dev/null 2>&1"; then
      echo "✓ $source_name ($source_ip) → $dest_name ($dest_ip)"
    else
      echo "✗ $source_name ($source_ip) → $dest_name ($dest_ip) FAILED" >&2
      connectivity_ok=false
    fi
  done
done

if [ "$connectivity_ok" = false ]; then
  echo "" >&2
  echo "Network connectivity test failed!" >&2
  exit 1
fi

echo ""
echo "✓ All connectivity tests passed!"
