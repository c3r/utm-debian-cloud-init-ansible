#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib.sh"

require_cmd yq
require_cmd sudo
require_cmd ssh
require_cmd nc
require_cmd qemu-system-x86_64

load_scalar_vars

RUN_DIR="${REPO_ROOT}/build/run"
LOG_DIR="${REPO_ROOT}/build/logs"
mkdir -p "${RUN_DIR}" "${LOG_DIR}"

# Function to wait for SSH to become available on a given host and port
# Returns 0 if SSH is available within the timeout, or 1 if it times out
wait_for_ssh() {
  local host="$1"
  local port="$2"
  local timeout_sec=180
  local elapsed=0

  while [ "${elapsed}" -lt "${timeout_sec}" ]; do
    if nc -z "${host}" "${port}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  return 1
}

# Loop through each VM defined in the configuration and bootstrap it
# Read all VMs into an array to avoid stdin consumption issues
vm_rows=()
while IFS= read -r line; do
  vm_rows+=("$line")
done < <(node_rows)

for vm_row in "${vm_rows[@]}"; do
  IFS='|' read -r vm_name vm_ip vm_mac <<< "$vm_row"

  # Define paths and files for this VM
  disk_image="${REPO_ROOT}/${DISK_DIR}/${vm_name}.${DISK_FORMAT}"       # Path to the VM's disk image
  seed_iso="${REPO_ROOT}/${CLOUD_INIT_DIR}/${vm_name}/${vm_name}.iso"   # Path to the cloud-init seed ISO
  log_file="${LOG_DIR}/${vm_name}.log"                                  # Path to the log file for this VM
  pid_file="${RUN_DIR}/${vm_name}.pid"                                  # Path to the PID file for this VM

  echo "Bootstrapping ${vm_name} (${vm_ip})"

  # Start the VM
  sudo -n qemu-system-x86_64 \
    -machine pc \
    -cpu max \
    -m 2048 \
    -smp 2 \
    -nographic \
    -drive "file=${disk_image},if=virtio,format=${DISK_FORMAT}" \
    -drive "file=${seed_iso},if=virtio,media=cdrom,readonly=on" \
    -netdev "vmnet-bridged,id=net0,ifname=${BRIDGE_INTERFACE}" \
    -device "virtio-net-pci,netdev=net0,mac=${vm_mac}" \
    -boot order=c \
    -serial mon:stdio \
    >"${log_file}" 2>&1 </dev/null &

  echo $! >"${pid_file}"

# Wait for SSH to become available
  if ! wait_for_ssh "${vm_ip}" "${SSH_PORT}"; then
    echo "Timed out waiting for SSH on ${vm_name} (${vm_ip}:${SSH_PORT})" >&2
    exit 1
  fi

# Wait for cloud-init to finish
  ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "${CLOUD_USER}@${vm_ip}" \
    'cloud-init status --wait'

# Power off the VM gracefully
  ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "${CLOUD_USER}@${vm_ip}" \
    'sudo poweroff' || true

# Wait for the VM process to exit
# We give it a generous timeout to ensure the VM has fully shut down before we proceed
# If the VM does not shut down within the timeout, we will forcefully kill it in the next step
  pid="$(cat "${pid_file}")"
  for _ in $(seq 1 60); do
    if ! kill -0 "${pid}" 2>/dev/null; then
      break
    fi
    sleep 2
  done

# Clean up the PID file
  rm -f "${pid_file}" 
  echo "Bootstrap complete for ${vm_name}"
done
