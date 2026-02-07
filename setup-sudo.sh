#!/usr/bin/env bash
set -euo pipefail

# Configure passwordless sudo for QEMU execution.
# Usage:
#   sudo ./setup-sudo.sh
#
# This will:
#  - allow passwordless execution of qemu-system-x86_64 for the current user

USER_NAME="${SUDO_USER:-${USER}}"

if [[ "$EUID" -ne 0 ]]; then
  echo "Please run as root: sudo ./setup-sudo.sh" >&2
  exit 1
fi

cat > /etc/sudoers.d/qemu-run <<EOF
${USER_NAME} ALL=(root) NOPASSWD: /usr/local/bin/qemu-system-x86_64 *
EOF

chmod 440 /etc/sudoers.d/qemu-run

echo "Sudo configuration installed for user: ${USER_NAME}"
