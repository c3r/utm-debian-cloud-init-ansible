#!/usr/bin/env bash
set -euo pipefail

# Configure passwordless sudo for QEMU run script and keep required env vars.
# Usage:
#   ./scripts/setup-sudo.sh
#
# This will:
#  - allow NET_MODE and NET_IF env vars through sudo
#  - allow passwordless execution of qemu/run.sh for the current user

USER_NAME="${SUDO_USER:-${USER}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_SCRIPT="${SCRIPT_DIR}/qemu/run.sh"

if [[ "$EUID" -ne 0 ]]; then
  echo "Please run as root: sudo ./scripts/setup-sudo.sh" >&2
  exit 1
fi

cat > /etc/sudoers.d/qemu-env <<'EOF'
Defaults env_keep += "NET_MODE NET_IF"
EOF

cat > /etc/sudoers.d/qemu-run <<EOF
${USER_NAME} ALL=(root) NOPASSWD: ${RUN_SCRIPT} *
EOF

chmod 440 /etc/sudoers.d/qemu-env /etc/sudoers.d/qemu-run

echo "Sudo configuration installed for user: ${USER_NAME}"
