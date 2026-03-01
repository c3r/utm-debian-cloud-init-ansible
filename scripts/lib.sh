#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${REPO_ROOT}/group_vars/all.yml"

# The require_cmd function checks if a given command is available in the system's PATH. If the command is not found, it prints an error message and exits the script with a non-zero status. This is used to ensure that all necessary dependencies are installed before running the other scripts.
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

# The load_scalar_vars function reads scalar variables from the configuration file using yq and exports them as environment variables. This allows the other scripts to access these variables when generating cloud-init configurations, creating disk images, and managing VMs. The variables include information about the cloud user, SSH port, network interface, gateway, bridge interface, disk directory, cloud-init directory, disk format, base image path, development SSH key, and DNS settings.
load_scalar_vars() {
  CLOUD_USER=$(yq '.cloud_user' "${CONFIG_FILE}")
  SSH_PORT=$(yq '.ssh_port // 22' "${CONFIG_FILE}")
  NETWORK_INTERFACE=$(yq '.network_interface' "${CONFIG_FILE}")
  GATEWAY=$(yq '.gateway' "${CONFIG_FILE}")
  BRIDGE_INTERFACE=$(yq '.bridge_interface' "${CONFIG_FILE}")
  DISK_DIR=$(yq '.disk_dir' "${CONFIG_FILE}")
  CLOUD_INIT_DIR=$(yq '.cloud_init_dir' "${CONFIG_FILE}")
  DISK_FORMAT=$(yq '.disk_format // "qcow2"' "${CONFIG_FILE}")
  BASE_IMAGE_PATH=$(yq '.base_image_path' "${CONFIG_FILE}")
  DEV_SSH_KEY=$(yq '.dev_ssh_key' "${CONFIG_FILE}")
  DNS_INLINE=$(yq -r '.dns | map("      - " + .) | join("\n")' "${CONFIG_FILE}")
  
  export CLOUD_USER SSH_PORT NETWORK_INTERFACE GATEWAY BRIDGE_INTERFACE DISK_DIR CLOUD_INIT_DIR DISK_FORMAT BASE_IMAGE_PATH DEV_SSH_KEY DNS_INLINE
}

# The node_names function uses yq to extract the names of the VMs defined in the configuration file. It reads the keys from the "nodes" section of the YAML file and prints them one per line. This is used by other scripts to loop through the defined VMs and perform actions such as creating disk images, generating cloud-init configurations, and managing VM processes.
node_names() {
  yq -r '.nodes | keys[]' "${CONFIG_FILE}"
}

# The node_rows function uses yq to extract the details of the VMs defined in the configuration file. It reads the keys and values from the "nodes" section of the YAML file and prints them in a pipe-separated format (name|ip|mac). This is used by other scripts to loop through the defined VMs and perform actions such as creating disk images, generating cloud-init configurations, and managing VM processes.
node_rows() {
  yq -r '.nodes | to_entries[] | "\(.key)|\(.value.ip)|\(.value.mac)"' "${CONFIG_FILE}"
}
