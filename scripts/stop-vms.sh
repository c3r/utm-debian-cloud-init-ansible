#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib.sh"

require_cmd yq
require_cmd sudo

RUN_DIR="${REPO_ROOT}/build/run"

# This script stops all running VMs that were started by the run-vms.sh script. It does this by reading the PID files for each VM and sending a termination signal to those processes. If the processes do not terminate within a reasonable time, it will forcefully kill them. It also cleans up the PID files after stopping the VMs.
if [ -d "${RUN_DIR}" ]; then
  while IFS= read -r pid_file; do
    # Read the PID from the file and attempt to gracefully terminate the process.
    pid="$(cat "${pid_file}" 2>/dev/null || true)"

    # If the PID is valid and the process is still running, send a termination signal. We give it a short timeout to allow the process to exit gracefully.
    if [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" || true
      sleep 1
      if kill -0 "${pid}" 2>/dev/null; then
        kill -9 "${pid}" || true
      fi
      echo "Stopped PID ${pid}"
    fi
    rm -f "${pid_file}"
  done < <(find "${RUN_DIR}" -name '*.pid' -type f)
fi

# As an extra safety measure, we also check for any qemu-system-x86_64 processes that match the VM names and kill them. This is to ensure that any VMs that may not have been properly stopped by the PID files are also terminated. We use pkill with a pattern that matches the VM names to target only the relevant processes.
while IFS= read -r vm_name; do
  sudo pkill -f "qemu-system-x86_64.*${vm_name}" >/dev/null 2>&1 || true
done < <(node_names)

echo "Stop sequence finished"
