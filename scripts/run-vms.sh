#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib.sh"

require_cmd yq
require_cmd sudo
require_cmd qemu-system-x86_64

load_scalar_vars

RUN_DIR="${REPO_ROOT}/build/run"
LOG_DIR="${REPO_ROOT}/build/logs"
mkdir -p "${RUN_DIR}" "${LOG_DIR}"

# Loop through each VM defined in the configuration
# Read all VMs into an array to avoid stdin consumption issues
vm_rows=()
while IFS= read -r line; do
  vm_rows+=("$line")
done < <(node_rows)

for vm_row in "${vm_rows[@]}"; do
  IFS='|' read -r vm_name vm_ip vm_mac <<< "$vm_row"

  disk_image="${REPO_ROOT}/${DISK_DIR}/${vm_name}.${DISK_FORMAT}"
  seed_iso="${REPO_ROOT}/${CLOUD_INIT_DIR}/${vm_name}/${vm_name}.iso"
  log_file="${LOG_DIR}/${vm_name}.log"
  pid_file="${RUN_DIR}/${vm_name}.pid"

  if [ ! -f "${disk_image}" ]; then
    echo "Missing disk image: ${disk_image}" >&2
    exit 1
  fi

  if [ ! -f "${seed_iso}" ]; then
    echo "Missing seed ISO: ${seed_iso}" >&2
    exit 1
  fi

# Start the VM using qemu-system-x86_64 with the specified parameters. We run it in the background and redirect its output to a log file. We also save its PID to a file for later management (e.g., stopping the VM).
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
  echo "Started ${vm_name} (pid $(cat "${pid_file}"))"
done
